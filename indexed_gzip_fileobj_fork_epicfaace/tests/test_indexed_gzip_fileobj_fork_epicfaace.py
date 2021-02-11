#!/usr/bin/env python
#
# test_indexed_gzip_fileobj_fork_epicfaace.py - Python wrapper around ctest_indexed_gzip_fileobj_fork_epicfaace.pyx.
#
# Author: Paul McCarthy <pauldmccarthy@gmail.com>
#


import pytest

from . import ctest_indexed_gzip_fileobj_fork_epicfaace


pytestmark = pytest.mark.indexed_gzip_fileobj_fork_epicfaace_test


def test_open_close(testfile, nelems, seed):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_open_close(testfile, nelems, seed, False)

def test_open_function(testfile, nelems):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_open_function(testfile, nelems)

def test_open_close_drop_handles(testfile, nelems, seed):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_open_close(testfile, nelems, seed, True)

def test_open_close_ctxmanager(testfile, nelems, seed):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_open_close_ctxmanager(
        testfile, nelems, seed, False)

def test_open_close_ctxmanager_drop_handles(testfile, nelems, seed):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_open_close_ctxmanager(testfile, nelems, seed, True)

def test_atts(testfile):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_atts(testfile, False)

def test_atts_drop_handles(testfile):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_atts(testfile, True)

def test_init_failure_cases(concat):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_init_failure_cases(concat, False)

def test_init_failure_cases_drop_handles(concat):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_init_failure_cases(concat, True)

def test_init_success_cases(concat):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_init_success_cases(concat, False)

def test_init_success_cases_drop_handles(concat):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_init_success_cases(concat, True)

def test_create_from_open_handle(testfile, nelems, seed):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_create_from_open_handle(
        testfile, nelems, seed, False)

def test_accept_filename_or_fileobj(testfile, nelems):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_accept_filename_or_fileobj(testfile, nelems)

def test_create_from_open_handle_drop_handles(testfile, nelems, seed):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_create_from_open_handle(
        testfile, nelems, seed, True)

def test_handles_not_dropped(testfile, nelems, seed):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_handles_not_dropped(testfile, nelems, seed)

def test_manual_build():
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_manual_build()

def test_read_all(testfile, nelems, use_mmap):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_read_all(testfile, nelems, use_mmap, False)

def test_read_all_drop_handles(testfile, nelems, use_mmap):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_read_all(testfile, nelems, use_mmap, True)

def test_read_beyond_end(concat):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_read_beyond_end(concat, False)

def test_seek(concat):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_seek(concat)

def test_read_beyond_end_drop_handles(concat):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_read_beyond_end(concat, True)

def test_seek_and_read(testfile, nelems, niters, seed):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_seek_and_read(
        testfile, nelems, niters, seed, False)

def test_seek_and_read_drop_handles(testfile, nelems, niters, seed):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_seek_and_read(testfile, nelems, niters, seed, True)

def test_seek_and_tell(testfile, nelems, niters, seed):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_seek_and_tell(
        testfile, nelems, niters, seed, False)

def test_seek_and_tell_drop_handles(testfile, nelems, niters, seed):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_seek_and_tell(testfile, nelems, niters, seed, True)

def test_pread():
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_pread()

def test_readinto():
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_readinto(False)

def test_readinto_drop_handles():
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_readinto(True)

def test_readline():
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_readline(False)

def test_readline_drop_handles():
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_readline(True)

def test_readline_sizelimit():
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_readline_sizelimit(False)

def test_readline_sizelimit_drop_handles():
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_readline_sizelimit(True)

def test_readlines():
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_readlines(False)

def test_readlines_drop_handles():
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_readlines(True)

def test_readlines_sizelimit():
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_readlines_sizelimit(False)

def test_readlines_sizelimit_drop_handles():
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_readlines_sizelimit(True)

def test_iter():
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_iter(False)

def test_iter_drop_handles():
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_iter(True)

@pytest.mark.slow_test
def test_get_index_seek_points():
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_get_index_seek_points()

def test_import_export_index():
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_import_export_index()

def test_wrapper_class():
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_wrapper_class()

def test_size_multiple_of_readbuf():
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_size_multiple_of_readbuf()

@pytest.mark.slow_test
def test_picklable():
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_picklable()

@pytest.mark.slow_test
def test_copyable():
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_copyable()

@pytest.mark.slow_test
def test_multiproc_serialise():
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_multiproc_serialise()

@pytest.mark.slow_test
def test_32bit_overflow(niters, seed):
    ctest_indexed_gzip_fileobj_fork_epicfaace.test_32bit_overflow(niters, seed)
