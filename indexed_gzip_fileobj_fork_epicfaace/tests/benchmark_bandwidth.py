#!/usr/bin/env python
#
# benchmark.py - benchmark indexed_gzip_fileobj_fork_epicfaace
#
# Author: Paul McCarthy <pauldmccarthy@gmail.com>
#


from __future__ import print_function

import            os
import os.path as op
import            sys
import            gzip
import            time
import            shutil
import            hashlib
import            tempfile
import            argparse
import            contextlib

import numpy as np

import indexed_gzip_fileobj_fork_epicfaace as igzip


@contextlib.contextmanager
def tempdir():
    testdir = tempfile.mkdtemp()
    prevdir = os.getcwd()
    try:
        os.chdir(testdir)
        yield testdir

    finally:
        os.chdir(prevdir)
        shutil.rmtree(testdir)


def size(filename):
    with open(filename, 'rb') as f:
        f.seek(-1, 2)
        return f.tell()


def gen_file(fname, nbytes):
    nelems = int(nbytes / 4)

    data = np.random.randint(0, 2 ** 32, nelems, dtype=np.uint32)

    # zero out 10% so there is something to compress
    zeros = np.random.randint(0, nelems, int(nelems / 10.0))
    data[zeros] = 0
    data = data.tobytes()

    # write 1GB max at a time - the gzip
    # module doesn't like writing >= 4GB
    # in one go.
    chunksize = 1073741824

    while len(data) > 0:
        chunk = data[:chunksize]
        data  = data[chunksize:]
        with gzip.open(fname, 'ab') as outf:
            outf.write(chunk)


def benchmark_file(fobj, chunksize, update):
    start   = time.time()
    hashobj = hashlib.md5()

    while True:
        data = fobj.read(chunksize)
        update(fobj.tell())
        if not data:
            break
        hashobj.update(data)

    end     = time.time()
    elapsed = end - start

    return str(hashobj.hexdigest()), elapsed


def benchmark(filename, uncompressed_size):
    names = [
        'GzipFile',
        'IndexedGzipFile(drop_handles=True, spacing=0)',
        'IndexedGzipFile(drop_handles=False, spacing=0)',
        'IndexedGzipFile(drop_handles=True, spacing=32 MiB)',
        'IndexedGzipFile(drop_handles=False, spacing=32 MiB)',
        'IndexedGzipFile(drop_handles=True, spacing=32 MiB, readbuf_size=uncompressed_size)',
        'IndexedGzipFile(drop_handles=False, spacing=32 MiB, readbuf_size=uncompressed_size)'
    ]
    namelen = max([len(n) for n in names])
    namefmt = '{{:<{}s}}'.format(namelen + len( "Read 131072 KiB chunks" ))

    fobjs = [
        lambda : gzip.GzipFile(        filename, 'rb'),
        lambda : igzip.IndexedGzipFile(filename, drop_handles=True, spacing=0),
        lambda : igzip.IndexedGzipFile(filename, drop_handles=False, spacing=0),
        lambda : igzip.IndexedGzipFile(filename, drop_handles=True, spacing=32 * 1024 * 1024),
        lambda : igzip.IndexedGzipFile(filename, drop_handles=False, spacing=32 * 1024 * 1024),
        lambda : igzip.IndexedGzipFile(filename, drop_handles=True, spacing=32 * 1024 * 1024, readbuf_size=uncompressed_size),
        lambda : igzip.IndexedGzipFile(filename, drop_handles=False, spacing=32 * 1024 * 1024, readbuf_size=uncompressed_size),
    ]

    firstMd5 = None
    for name, fobj in zip(names, fobjs):
        for chunksize in [4 * 1024, 32 * 1024, 128 * 1024, 1024 * 1024, 32 * 1024 * 1024, uncompressed_size]:
            def update(i):
                label = f"Read {chunksize // 1024:6} KiB chunks from {namefmt.format(name)}"
                print(f'\r{label} {100.0 * i / uncompressed_size:6.2f} %', end='')
                sys.stdout.flush()

            with fobj() as f:
                md5, time = benchmark_file(f, chunksize, update)

            print(f'  {md5} {time:0.3f} s')

            if firstMd5 is None:
                firstMd5 = md5
            else:
                assert firstMd5 == md5

        print()


if __name__ == '__main__':

    parser = argparse.ArgumentParser('indexe_gzip benchmark')

    parser.add_argument('-b',
                        '--bytes',
                        type=int,
                        help='Uncompressed size of test file in bytes. '
                             'Ignored if a --file is specified',
                        default=128 * 1024 * 1024)
    parser.add_argument('-f',
                        '--file',
                        type=str,
                        help='Test file (default: generate one)')
    parser.add_argument('-r',
                        '--randomseed',
                        type=int,
                        help='Seed for random number generator')

    namespace = parser.parse_args()

    if namespace.randomseed is not None:
        np.random.seed(namespace.seed)

    if namespace.file is not None:
        namespace.file = op.abspath(namespace.file)

    with tempdir():
        if namespace.file is None:

            print('Generating test data ({:0.2f} MiB)...'.format(
                namespace.bytes / (1024 * 1024)), end='')
            sys.stdout.flush()

            namespace.file = 'test.gz'

            gen_file(namespace.file, namespace.bytes)

            print(' {:0.2f} MiB compressed'.format(
                size(namespace.file) / (1024 * 1024) ))

        if namespace.randomseed is not None:
            np.random.seed(namespace.seed)

        benchmark(namespace.file, namespace.bytes)
