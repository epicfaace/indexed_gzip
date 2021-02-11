#
# Tests for the zran module.
#
# Author: Paul McCarthy <pauldmccarthy@gmail.com>
#

from __future__ import print_function
from __future__ import division

import                    os
import os.path         as op
import itertools       as it
import subprocess      as sp
import                    sys
import                    time
import                    gzip
import                    shutil
import                    random
import                    hashlib
import                    tempfile
import                    threading
import                    contextlib

import numpy as np

cimport numpy as np

from posix.types cimport  off_t
from io import BytesIO

from libc.stdio  cimport (SEEK_SET,
                          SEEK_CUR,
                          SEEK_END)

from libc.string cimport memset, memcmp

from cpython.mem cimport (PyMem_Malloc,
                          PyMem_Realloc,
                          PyMem_Free)
from cpython.ref cimport PyObject

from posix.mman cimport (mmap,
                         munmap,
                         PROT_READ,
                         PROT_WRITE,
                         MAP_ANON,
                         MAP_SHARED)


from . import poll, check_data_valid, tempdir


cdef extern from "sys/mman.h":
    cdef enum:
        MAP_FAILED

cimport indexed_gzip_fileobj_fork_epicfaace.zran as zran

np.import_array()


cdef read_element(zran.zran_index_t *index, element, nelems, seek=True):

    cdef void *buffer

    buf    = ReadBuffer(8)
    buffer = buf.buffer

    if   element >= nelems: expseek = zran.ZRAN_SEEK_EOF
    else:                   expseek = zran.ZRAN_SEEK_OK

    if   element >= nelems: exptell = (nelems * 8)
    else:                   exptell = element * 8


    if seek:
        gotseek = zran.zran_seek(index, element * 8, SEEK_SET, NULL)
        gottell = zran.zran_tell(index)
        try:
            assert gotseek == expseek
            assert gottell == exptell
        except:
            print('expseek: {}'.format(expseek))
            print('exptell: {}'.format(exptell))
            print('gotseek: {}'.format(gotseek))
            print('gottell: {}'.format(gottell))
            raise


    if   element >= nelems: expread = zran.ZRAN_READ_EOF
    else:                   expread = 8

    if   element >= nelems: exptell = (nelems * 8)
    else:                   exptell = (element + 1) * 8

    gotread = zran.zran_read(index, buffer, 8)
    gottell = zran.zran_tell(index)

    try:
        assert gotread == expread
        assert gottell == exptell
    except:
        print('nelems:  {}'.format(nelems))
        print('element: {}'.format(element))
        print('expread: {}'.format(expread))
        print('exptell: {}'.format(exptell))
        print('gotread: {}'.format(gotread))
        print('gottell: {}'.format(gottell))
        raise

    if element < nelems:
        pybuf = <bytes>(<char *>buffer)[:8]
        val   = np.ndarray(1, np.uint64, buffer=pybuf)
        return val[0]
    else:
        return None


cdef class ReadBuffer:
    """Wrapper around a chunk of memory.

    .. see:: http://docs.cython.org/src/tutorial/memory_allocation.html
    """

    cdef void *buffer
    """A raw chunk of bytes. """

    cdef bint use_mmap
    """
    """

    cdef size_t size
    """
    """

    cdef object mmap_fd
    cdef object mmap_path


    def __cinit__(self, size_t size, use_mmap=False):
        """Allocate ``size`` bytes of memory. """

        self.use_mmap  = use_mmap
        self.mmap_fd   = None
        self.mmap_path = None
        self.size      = size
        self.buffer    = NULL

        if not self.use_mmap:
            self.buffer = PyMem_Malloc(size)

            memset(self.buffer, 0, size);

        else:

            fd, path = tempfile.mkstemp('readbuf_mmap_{}'.format(id(self)))

            print('Memory-mapping {:0.2f} GB ({})'.format(size / 1073741824., path))

            def initmem():

                towrite = size

                while towrite > 0:

                    zeros    = np.zeros(min(towrite, 134217728), dtype=np.uint8)
                    towrite -= len(zeros)

                    os.write(fd, zeros.tostring())

            th = threading.Thread(target=initmem)
            th.start()
            poll(lambda : not th.is_alive())

            self.mmap_fd   = fd
            self.mmap_path = path
            self.buffer    = mmap(NULL,
                                  size,
                                  PROT_READ | PROT_WRITE,
                                  MAP_SHARED,
                                  fd,
                                  0)

            if self.buffer == <void*>MAP_FAILED:
                raise RuntimeError('mmap fail')

        if not self.buffer:
            raise RuntimeError('ReadBuffer init fail')


    def resize(self, size_t size):
        """Re-allocate the memory to the given ``size``. """

        if self.use_mmap:
            raise NotImplementedError('Cannot resize a memmapped array!')

        buf = PyMem_Realloc(self.buffer, size)

        if not buf:
            raise MemoryError('PyMem_Realloc fail')

        self.buffer = buf
        self.size   = size


    def __dealloc__(self):
        """Free the mwmory. """

        if not self.use_mmap:
            PyMem_Free(self.buffer)
        else:
            munmap(self.buffer, self.size)
            os.close( self.mmap_fd)
            os.remove(self.mmap_path)

def test_file_funcs(testfile):
    """Tests Python wrapper C functions."""
    # fread
    f = BytesIO(b"abc")
    cdef char buf[3]
    elems_read = zran._fread_python(buf, 1, 3, <PyObject*>f)
    assert elems_read == 3
    assert f.tell() == 3
    assert buf[0:3] == b"abc"

    # ftell
    f = BytesIO(b"abc")
    assert zran._ftell_python(<PyObject*>f) == 0
    f.seek(2)
    assert zran._ftell_python(<PyObject*>f) == 2
    
    # fseek
    f = BytesIO(b"abc")
    zran._fseek_python(<PyObject*>f, 1, SEEK_SET)
    assert f.tell() == 1
    zran._fseek_python(<PyObject*>f, -1, SEEK_END)
    assert f.tell() == 2
    zran._fseek_python(<PyObject*>f, 100, SEEK_SET)
    assert f.tell() == 100

    # feof
    f = BytesIO(b"abc")
    f.seek(0)
    assert zran._feof_python(<PyObject*>f, 3) == 0
    f.seek(3)
    assert zran._feof_python(<PyObject*>f, 3) == 1

    # ferror
    f = BytesIO(b"abc")
    assert zran._ferror_python(<PyObject*>f) == 0

    # fflush
    f = BytesIO(b"abc")
    zran._fflush_python(<PyObject*>f)

    # fwrite
    f = BytesIO(b"abc")
    cdef char* inp = 'de'
    elems_written = zran._fwrite_python(inp, 1, 2, <PyObject*>f)
    assert elems_written == 2
    assert f.tell() == 2
    f.seek(0)
    assert f.read() == b"dec"

    # getc
    f = BytesIO(b"dbc")
    assert zran._getc_python(<PyObject*>f) == ord(b"d"), zran._getc_python(<PyObject*>f)


def test_init(testfile):
    """Tests a bunch of permutations of the parameters to zran_init. """

    spacings      = [0, 16384, 32768, 65536, 524288, 1048576, 2097152, 4194304]
    window_sizes  = [0, 8192, 16384, 32768, 65536, 131072]
    readbuf_sizes = [0, 8192, 16384, 24576, 32768, 65536, 131072]
    flags         = [0, zran.ZRAN_AUTO_BUILD]

    cdef zran.zran_index_t index

    with open(testfile, 'rb') as pyfid:

        for s, w, r, f in it.product(spacings,
                                     window_sizes,
                                     readbuf_sizes,
                                     flags):

            result = not zran.zran_init(&index, <PyObject*>pyfid, s, w, r, f)

            expected = True

            # zran_init should fail if the point spacing
            # is less than the window size

            if w == 0: w = 32768
            if s == 0: s = 1048576
            if r == 0: r = 16384

            expected = (w >= 32768) and (s > w)

            assert result == expected

            zran.zran_free(&index)


def test_init_file_modes(testfile):

    modes = ['r', 'r+', 'w', 'w+', 'a', 'a+']

    files = [testfile, testfile,
             'dummy.gz', 'dummy.gz', 'dummy.gz', 'dummy.gz']

    cdef zran.zran_index_t index
    cdef bytes             bmode
    cdef char             *cmode

    for filename, mode in zip(files, modes):

        with open(filename, mode) as pyfid:

            bmode    = mode.encode()
            cmode    = bmode

            expected = 1

            result = not zran.zran_init(&index, <PyObject*>pyfid, 0, 0, 0, 0)

            assert result == expected

            zran.zran_free(&index)

        if filename == 'dummy.gz' and op.exists(filename):
            os.remove(filename)


def test_no_auto_build(testfile, nelems):

    cdef zran.zran_index_t index
    cdef void             *buffer

    filesize     = nelems * 8
    indexSpacing = max(1048576, filesize // 1500)
    bufSize      = 1048576
    buf          = ReadBuffer(bufSize)
    buffer       = buf.buffer

    with open(testfile, 'rb') as pyfid:

        assert not zran.zran_init(&index,
                                  <PyObject*>pyfid,
                                  indexSpacing,
                                  32768,
                                  131072,
                                  0)

        assert zran.zran_seek(&index, 0, SEEK_SET, NULL) == zran.ZRAN_SEEK_OK
        assert zran.zran_tell(&index) == 0
        assert zran.zran_seek(&index, 1, SEEK_SET, NULL) == zran.ZRAN_SEEK_NOT_COVERED
        assert zran.zran_tell(&index) == 0

        gotread = zran.zran_read(&index, buffer, bufSize)
        gottell = zran.zran_tell(&index)

        if bufSize > filesize: expread = filesize
        else:                  expread = bufSize

        if bufSize > filesize: exptell = filesize
        else:                  exptell = bufSize

        try:
            assert gotread == expread
            assert gottell == exptell
        except:
            print("expread: {}".format(expread))
            print("gotread: {}".format(gotread))
            print("exptell: {}".format(exptell))
            print("gottell: {}".format(gottell))
            raise

        pybuf = <bytes>(<char *>buffer)[:gotread]
        data  = np.ndarray(gotread // 8, np.uint64, pybuf)

        assert check_data_valid(data, 0)

        if bufSize < filesize:
            assert zran.zran_read(&index, buffer, bufSize) == zran.ZRAN_READ_NOT_COVERED


def test_seek_to_end(testfile, nelems):

    cdef zran.zran_index_t index

    filesize = nelems * 8

    seek_point   = filesize - 1
    indexSpacing = max(524288, filesize // 1500)

    with open(testfile, 'rb') as pyfid:

        assert not zran.zran_init(&index,
                                  <PyObject*>pyfid,
                                  indexSpacing,
                                  32768,
                                  131072,
                                  zran.ZRAN_AUTO_BUILD)

        assert zran.zran_seek(&index, seek_point, SEEK_SET, NULL) == 0

        zt = zran.zran_tell(&index)

        assert zt == seek_point

        zran.zran_free(&index)


def test_seek_cur(testfile, nelems):

    cdef zran.zran_index_t index

    filesize     = nelems * 8
    indexSpacing = max(524288, filesize // 1500)
    seekstep     = max(1, (nelems - 1) // 500)
    curelem      = 0;

    with open(testfile, 'rb') as pyfid:

        assert not zran.zran_init(&index,
                                  <PyObject*>pyfid,
                                  indexSpacing,
                                  32768,
                                  131072,
                                  zran.ZRAN_AUTO_BUILD)

        while curelem < nelems:

            if (curelem + seekstep) * 8 < filesize: exp = zran.ZRAN_SEEK_OK
            else:                                   exp = zran.ZRAN_SEEK_EOF


            out = zran.zran_seek(&index, seekstep * 8, SEEK_CUR, NULL)
            assert out == exp, out

            if exp == zran.ZRAN_SEEK_EOF:
                break

            curelem += seekstep
            zt = zran.zran_tell(&index)
            val = read_element(&index, curelem, nelems, False)

            assert zt  == curelem * 8
            assert val == curelem

            assert zran.zran_seek(&index, -8, SEEK_CUR, NULL) == zran.ZRAN_SEEK_OK

        zran.zran_free(&index)


def test_seek_end(testfile, nelems):
    cdef zran.zran_index_t index

    filesize     = nelems * 8
    indexSpacing = max(131072, filesize // 1500)
    seekstep     = max(1, (nelems - 1) // 500)
    curelem      = 0

    with open(testfile, 'rb') as pyfid:

        assert not zran.zran_init(&index,
                                  <PyObject*>pyfid,
                                  indexSpacing,
                                  32768,
                                  131072,
                                  zran.ZRAN_AUTO_BUILD)

        assert zran.zran_seek(&index, -10, SEEK_END, NULL) == zran.ZRAN_SEEK_INDEX_NOT_BUILT
        assert zran.zran_seek(&index,  20, SEEK_SET, NULL) == zran.ZRAN_SEEK_OK
        assert zran.zran_tell(&index)                      == 20
        assert zran.zran_seek(&index, -10, SEEK_END, NULL) == zran.ZRAN_SEEK_INDEX_NOT_BUILT

        assert zran.zran_build_index(&index, 0, 0)         == 0

        assert zran.zran_seek(&index,  0, SEEK_END, NULL) == zran.ZRAN_SEEK_EOF
        assert zran.zran_tell(&index)                     == filesize
        assert zran.zran_seek(&index, -1, SEEK_END, NULL) == zran.ZRAN_SEEK_OK
        assert zran.zran_tell(&index)                     == filesize - 1

        assert zran.zran_seek(&index,  1,             SEEK_END, NULL) == zran.ZRAN_SEEK_EOF
        assert zran.zran_tell(&index)                                 == filesize
        assert zran.zran_seek(&index,  -filesize - 1, SEEK_END, NULL) == zran.ZRAN_SEEK_FAIL
        assert zran.zran_seek(&index,  -filesize,     SEEK_END, NULL) == zran.ZRAN_SEEK_OK
        assert zran.zran_tell(&index)                                 == 0

        while curelem < nelems:
            seekloc = filesize - ((nelems + curelem - 1) * 8)

            if seekloc >= 0: exp = zran.ZRAN_SEEK_EOF
            else:            exp = zran.ZRAN_SEEK_OK

            assert zran.zran_seek(&index, seekloc, SEEK_END, NULL) == exp

            if exp == zran.ZRAN_SEEK_EOF:
                break

            curelem += seekstep
            zt = zran.zran_tell(&index)
            val = read_element(&index, curelem, nelems, False)

            assert zt  == curelem * 8
            assert val == curelem

        zran.zran_free(&index)


def test_seek_beyond_end(testfile, nelems):

    cdef zran.zran_index_t index

    filesize     = nelems * 8
    indexSpacing = max(524288, filesize // 1500)
    seekpoints   = [filesize - 10,
                    filesize - 2,
                    filesize - 1,
                    filesize,
                    filesize + 1,
                    filesize + 2,
                    filesize + 10]

    with open(testfile, 'rb') as pyfid:

        assert not zran.zran_init(&index,
                                  <PyObject*>pyfid,
                                  indexSpacing,
                                  32768,
                                  131072,
                                  zran.ZRAN_AUTO_BUILD)

        for sp in seekpoints:

            zs = zran.zran_seek(&index, sp, SEEK_SET, NULL)

            if sp >= filesize: expected = zran.ZRAN_SEEK_EOF
            else:              expected = zran.ZRAN_SEEK_OK

            try:
                assert zs == expected

            except:
                print("{} != {} [sp={}, size={}]".format(zs, expected, sp, filesize))
                raise

            zt = zran.zran_tell(&index)

            if sp >= filesize: expected = filesize
            else:              expected = sp

            try:
                assert zt == expected

            except:
                print("{} != {}".format(zt, expected))
                raise

        zran.zran_free(&index)


def test_sequential_seek_to_end(testfile, nelems, niters):

    cdef zran.zran_index_t index

    filesize   = nelems * 8

    seek_points = np.random.randint(0, filesize, niters, dtype=np.uint64)
    seek_points = np.sort(seek_points)
    indexSpacing = max(524288, filesize // 2000)

    with open(testfile, 'rb') as pyfid:

        assert not zran.zran_init(&index,
                                  <PyObject*>pyfid,
                                  indexSpacing,
                                  32768,
                                  131072,
                                  zran.ZRAN_AUTO_BUILD)

        for sp in seek_points:

            if sp >= filesize:
                expseek = zran.ZRAN_SEEK_EOF
                exptell = filesize
            else:
                expseek = zran.ZRAN_SEEK_OK
                exptell = sp

            seek = zran.zran_seek(&index, sp, SEEK_SET, NULL)
            tell = zran.zran_tell(&index)

            try:
                assert seek == expseek
                assert tell == exptell
            except:
                print("expseek: {}".format(expseek))
                print("exptell: {}".format(exptell))
                print("seek:    {}".format(seek))
                print("tell:    {}".format(tell))
                raise


        zran.zran_free(&index)


def test_random_seek(testfile, nelems, niters, seed):

    cdef zran.zran_index_t index

    filesize = nelems * 8

    seekpoints   = [random.randint(0, filesize) for i in range(niters)]
    indexSpacing = max(524288, filesize // 1000)

    with open(testfile, 'rb') as pyfid:

        assert not zran.zran_init(&index,
                                  <PyObject*>pyfid,
                                  indexSpacing,
                                  32768,
                                  131072,
                                  zran.ZRAN_AUTO_BUILD)

        for sp in seekpoints:

            assert zran.zran_seek(&index, sp, SEEK_SET, NULL) == 0

            zt = zran.zran_tell(&index)

            assert zt == sp

        zran.zran_free(&index)


def test_read_all(testfile, nelems, use_mmap):

    filesize = nelems * 8
    indexSpacing = max(524288, filesize // 1000)

    cdef zran.zran_index_t index
    cdef void             *buffer
    cdef np.npy_intp       nelemsp

    buf    = ReadBuffer(filesize, use_mmap=use_mmap)
    buffer = buf.buffer

    with open(testfile, 'rb') as pyfid:

        assert not zran.zran_init(&index,
                                  <PyObject*>pyfid,
                                  indexSpacing,
                                  32768,
                                  131072,
                                  zran.ZRAN_AUTO_BUILD)

        nbytes = zran.zran_read(&index, buffer, filesize)

        assert nbytes                 == filesize
        assert zran.zran_tell(&index) == nbytes

        zran.zran_free(&index)

    nelemsp = nbytes / 8.
    data    = np.PyArray_SimpleNewFromData(1, &nelemsp,  np.NPY_UINT64, buffer)

    assert check_data_valid(data, 0)


def test_seek_then_read_block(testfile, nelems, niters, seed, use_mmap):

    filesize  = nelems * 8

    indexSpacing = max(524288, filesize // 1000)
    buf          = ReadBuffer(filesize, use_mmap=use_mmap)
    seekelems    = np.random.randint(0, nelems - 1, niters, dtype=np.uint64)

    cdef zran.zran_index_t index
    cdef void             *buffer = buf.buffer
    cdef np.npy_intp       nelemsp

    with open(testfile, 'rb') as pyfid:

        assert not zran.zran_init(&index,
                                  <PyObject*>pyfid,
                                  indexSpacing,
                                  32768,
                                  131072,
                                  zran.ZRAN_AUTO_BUILD)

        for i, se in enumerate(seekelems):


            if se == nelems - 1:
                readelems = 1
            else:
                readelems = np.random.randint(1, nelems - se)

            start = time.time()

            print("{} / {}: reading {} elements from {} ... ".format(
                i, len(seekelems), readelems, se), end='')

            assert zran.zran_seek(&index, se * 8, SEEK_SET, NULL) == zran.ZRAN_SEEK_OK

            nbytes = zran.zran_read(&index, buffer, readelems * 8)

            try:
                assert nbytes                 == readelems * 8
                assert zran.zran_tell(&index) == (se + readelems) * 8
            except:
                print('seekelem:    {}'.format(se))
                print('readelems:   {}'.format(readelems))
                print('nbytes:      {}'.format(nbytes))
                print('  should be: {}'.format(readelems * 8))
                print('ftell:       {}'.format(zran.zran_tell(&index)))
                print('  should be: {}'.format((se + readelems) * 8))
                raise

            nelemsp = nbytes / 8.
            data    = np.PyArray_SimpleNewFromData(1, &nelemsp,  np.NPY_UINT64, buffer)

            assert check_data_valid(data, se, se + readelems)

            end = time.time()

            print("{:0.2f} seconds".format(end - start))

        zran.zran_free(&index)


def test_random_seek_and_read(testfile, nelems, niters, seed):

    cdef zran.zran_index_t index

    filesize = nelems * 8

    seekelems    = np.random.randint(0, nelems, niters)
    indexSpacing = max(524288, filesize // 1000)

    with open(testfile, 'rb') as pyfid:

        assert not zran.zran_init(&index,
                                  <PyObject*>pyfid,
                                  indexSpacing,
                                  32768,
                                  131072,
                                  zran.ZRAN_AUTO_BUILD)

        for se in seekelems:

            # Should never happen
            if se >= nelems: expval = None
            else:            expval = se

            val = read_element(&index, se, nelems, True)

            try:
                assert val == expval
            except:
                print("{} != {}".format(val, se))
                raise

        zran.zran_free(&index)


def test_read_all_sequential(testfile, nelems):

    cdef zran.zran_index_t index

    filesize = nelems * 8

    indexSpacing = max(524288, filesize // 1000)

    # Takes too long to read all elements
    seekelems = np.random.randint(0, nelems - 1, 10000, dtype=np.uint64)
    seekelems = np.sort(seekelems)

    with open(testfile, 'rb') as pyfid:

        assert not zran.zran_init(&index,
                                  <PyObject*>pyfid,
                                  indexSpacing,
                                  32768,
                                  131072,
                                  zran.ZRAN_AUTO_BUILD)

        for se in seekelems:

            val = read_element(&index, se, nelems, True)
            try:
                assert val == se
            except:
                print("{} != {}".format(val, se))
                print("{:x} != {:x}".format(val, se))
                raise

        zran.zran_free(&index)


def test_build_then_read(testfile, nelems, seed, use_mmap):

    filesize = nelems * 8

    indexSpacing = max(524288, filesize // 1000)
    buf          = ReadBuffer(filesize, use_mmap)
    seekelems    = np.random.randint(0, nelems - 1, 5000, dtype=np.uint64)

    cdef zran.zran_index_t index
    cdef void             *buffer = buf.buffer

    with open(testfile, 'rb') as pyfid:

        assert not zran.zran_init(&index,
                                  <PyObject*>pyfid,
                                  indexSpacing,
                                  32768,
                                  131072,
                                  zran.ZRAN_AUTO_BUILD)

        assert not zran.zran_build_index(&index, 0, 0)

        for se in seekelems:

            assert zran.zran_seek(&index, se * 8, SEEK_SET, NULL) == 0

            if se == nelems - 1:
                readelems = 1
            else:
                readelems = np.random.randint(1, min(nelems - se, 5000))

            nbytes = zran.zran_read(&index, buffer, readelems * 8)

            assert nbytes                 == readelems * 8
            assert zran.zran_tell(&index) == (se + readelems) * 8

            pybuf = <bytes>(<char *>buffer)[:nbytes]
            data  = np.ndarray(nbytes // 8, np.uint64, pybuf)

            for i, val in enumerate(data, se):
                assert val == i

        zran.zran_free(&index)


def test_readbuf_spacing_sizes(testfile, nelems, niters, seed):

    cdef zran.zran_index_t index

    spacings = [262144,  524288,  1048576,
                2097152, 4194304, 8388608]
    bufsizes = [16384,   65536,   131072,  262144,
                524288,  1048575, 1048576, 1048577,
                2097152, 4194304, 8388608]

    seekelems = np.random.randint(0, nelems, niters // 2)
    seekelems = np.concatenate((spacings, bufsizes, seekelems))

    for sbi, (spacing, bufsize) in enumerate(it.product(spacings, bufsizes)):

        with open(testfile, 'rb') as pyfid:

            print('{} / {}: spacing={}, bufsize={} ... '.format(
                sbi,
                len(spacings) * len(bufsizes),
                spacing, bufsize), end='')


            assert not zran.zran_init(&index,
                                      <PyObject*>pyfid,
                                      spacing,
                                      32768,
                                      bufsize,
                                      zran.ZRAN_AUTO_BUILD)

            for i, se in enumerate(seekelems):

                # print('{} / {}: {}'.format(i, len(seekelems), se))

                if se >= nelems: expval = None
                else:            expval = se

                val = read_element(&index, se, nelems, seek=True)

                try:
                    assert val == expval
                except:
                    print('{} != {}'.format(val, expval))
                    raise

            print()
            zran.zran_free(&index)

def test_export_then_import(testfile):

    cdef zran.zran_index_t  index1
    cdef zran.zran_index_t  index2
    cdef zran.zran_point_t *p1
    cdef zran.zran_point_t *p2

    indexSpacing = 1048576
    windowSize   = 32768
    readbufSize  = 131072
    flag         = 0

    with open(testfile, 'rb') as pyfid:

        assert not zran.zran_init(&index1,
                                  <PyObject*>pyfid,
                                  indexSpacing,
                                  windowSize,
                                  readbufSize,
                                  flag)

        assert not zran.zran_build_index(&index1, 0, 0)

        with open(testfile + '.idx.tmp', 'wb') as pyexportfid:
            ret  = zran.zran_export_index(&index1, <PyObject*>pyexportfid)
            assert not ret, str(ret)

    with open(testfile, 'rb') as pyfid:
        assert not zran.zran_init(&index2,
                                  <PyObject*>pyfid,
                                  indexSpacing,
                                  windowSize,
                                  readbufSize,
                                  flag)

        with open(testfile + '.idx.tmp', 'rb') as pyexportfid:
            ret  = zran.zran_import_index(&index2, <PyObject*>pyexportfid)
            assert not ret, str(ret)

        assert index2.compressed_size   == index1.compressed_size
        assert index2.uncompressed_size == index1.uncompressed_size
        assert index2.spacing           == index1.spacing
        assert index2.window_size       == index1.window_size
        assert index2.npoints           == index1.npoints

        ws = index1.window_size

        for i in range(index1.npoints):

            p1 = &index1.list[i]
            p2 = &index2.list[i]
            msg = 'Error at point %d' % i

            assert p2.cmp_offset   == p1.cmp_offset, msg
            assert p2.uncmp_offset == p1.uncmp_offset, msg
            assert p2.bits         == p1.bits, msg
            if i == 0:
                assert not p2.data, msg
                assert not p1.data, msg
            else:
                assert p2.data, msg
                assert p1.data, msg
                assert not memcmp(p2.data, p1.data, ws), msg

        zran.zran_free(&index1)
        zran.zran_free(&index2)


def test_export_import_no_points():

    cdef zran.zran_index_t index
    cdef void             *buffer

    data   = np.random.randint(1, 255, 100, dtype=np.uint8)
    buf    = ReadBuffer(100)
    buffer = buf.buffer

    with tempdir():

        with gzip.open('data.gz', 'wb') as f:
            f.write(data.tostring())

        with open('data.gz', 'rb')  as pyfid:
            assert zran.zran_init(&index,
                                  <PyObject*>pyfid,
                                  1048576,
                                  32768,
                                  131072,
                                  0) == 0
            output = zran.zran_read(&index, buffer, 100)
            assert output  == 100, output

            pybuf = <bytes>(<char *>buffer)[:100]
            assert np.all(np.frombuffer(pybuf, dtype=np.uint8) == data)

            with open('data.gz.index', 'wb') as pyidxfid:
                assert zran.zran_export_index(&index, <PyObject*>pyidxfid) == 0
            zran.zran_free(&index)

        with open('data.gz', 'rb')  as pyfid:
            assert zran.zran_init(&index,
                                  <PyObject*>pyfid,
                                  1048576,
                                  32768,
                                  131072,
                                  0) == 0

            with open('data.gz.index', 'rb') as pyidxfid:
                assert zran.zran_import_index(&index, <PyObject*>pyidxfid) == 0
            assert index.npoints == 0

            assert zran.zran_read(&index, buffer, 100)  == 100
            pybuf = <bytes>(<char *>buffer)[:100]
            assert np.all(np.frombuffer(pybuf, dtype=np.uint8) == data)
            zran.zran_free(&index)
