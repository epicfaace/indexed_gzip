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

    data = np.random.randint(0, 2 ** 8, nelems, dtype=np.uint32)

    # zero out 10% so there is something to compress
    zeros = np.random.randint(0, nelems, int(nelems / 10.0))
    data[zeros] = 0
    data = data.tostring()

    # write 1GB max at a time - the gzip
    # module doesn't like writing >= 4GB
    # in one go.
    chunksize = 1073741824

    while len(data) > 0:
        chunk = data[:chunksize]
        data  = data[chunksize:]
        with gzip.open(fname, 'ab') as outf:
            outf.write(chunk)


def benchmark_file(fobj, seeks, lens, update):

    start   = time.time()
    hashobj = hashlib.md5()

    for i, (s, l) in enumerate(zip(seeks, lens)):
        fobj.seek(s)
        data = fobj.read(l)
        hashobj.update(data)
        update(i)

    update(len(seeks))

    end     = time.time()
    elapsed = end - start

    return str(hashobj.hexdigest()), elapsed


def benchmark(filename, nseeks):

    nbytes = size(filename)
    seeks  = np.linspace(0, nbytes, nseeks, dtype=np.int)
    lens   = np.random.randint(10485, 167772, nseeks)

    np.random.shuffle(seeks)

    names = [
        'GzipFile',
        'IndexedGzipFile(drop_handles=True)',
        'IndexedGzipFile(drop_handles=False)'
    ]
    namelen = max([len(n) for n in names])
    namefmt = '{{:<{}s}}'.format(namelen)

    fobjs = [
        lambda : gzip.GzipFile(        filename, 'rb'),
        lambda : igzip.IndexedGzipFile(filename, drop_handles=True),
        lambda : igzip.IndexedGzipFile(filename, drop_handles=False),
    ]

    for name, fobj in zip(names, fobjs):

        def update(i):
            print('\r{} {:6.2f}%'.format(
                namefmt.format(name),
                100.0 * i / len(seeks)), end='')
            sys.stdout.flush()

        with fobj() as f:
            md5, time = benchmark_file(f, seeks, lens, update)

        print('  {} {:0.0f}s'.format(md5, time))


if __name__ == '__main__':

    parser = argparse.ArgumentParser('indexe_gzip benchmark')

    parser.add_argument('-b',
                        '--bytes',
                        type=int,
                        help='Uncompressed size of test file in bytes. '
                             'Ignored if a --file is specified',
                        default=167772)
    parser.add_argument('-s',
                        '--seeks',
                        type=int,
                        help='Number of random seeks',
                        default=1000)
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

            print('Generating test data ({:0.2f}MB)...'.format(
                namespace.bytes / 1048576.), end='')
            sys.stdout.flush()

            namespace.file = 'test.gz'

            gen_file(namespace.file, namespace.bytes)

            print(' {:0.2f}MB compressed'.format(
                size(namespace.file) / 1048576.0))

        if namespace.randomseed is not None:
            np.random.seed(namespace.seed)

        benchmark(namespace.file, namespace.seeks)
