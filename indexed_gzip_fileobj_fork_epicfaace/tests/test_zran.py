#!/usr/bin/env python
#
# test_zran.py - Python wrapper around ctest_zran.pyx.
#
# Author: Paul McCarthy <pauldmccarthy@gmail.com>
#

from __future__ import print_function

import sys

if not sys.platform.startswith("win"):
    # Run these tests only on POSIX systems
    import pytest

    import numpy as np

    from . import ctest_zran


    pytestmark = pytest.mark.zran_test


    def test_file_funcs(            testfile):                                 ctest_zran.test_file_funcs(                  testfile)
    def test_init(                  testfile):                                 ctest_zran.test_init(                  testfile)
    def test_init_file_modes(       testfile):                                 ctest_zran.test_init_file_modes(       testfile)
    def test_no_auto_build(         testfile, nelems):                         ctest_zran.test_no_auto_build(         testfile, nelems)
    def test_seek_to_end(           testfile, nelems):                         ctest_zran.test_seek_to_end(           testfile, nelems)
    def test_seek_cur(              testfile, nelems):                         ctest_zran.test_seek_cur(              testfile, nelems)
    def test_seek_end(              testfile, nelems):                         ctest_zran.test_seek_end(              testfile, nelems)
    def test_seek_beyond_end(       testfile, nelems):                         ctest_zran.test_seek_beyond_end(       testfile, nelems)
    def test_sequential_seek_to_end(testfile, nelems, niters):                 ctest_zran.test_sequential_seek_to_end(testfile, nelems, niters)
    def test_random_seek(           testfile, nelems, niters, seed):           ctest_zran.test_random_seek(           testfile, nelems, niters, seed)
    def test_read_all(              testfile, nelems, use_mmap):               ctest_zran.test_read_all(              testfile, nelems, use_mmap)
    @pytest.mark.slow_test
    def test_seek_then_read_block(  testfile, nelems, niters, seed, use_mmap): ctest_zran.test_seek_then_read_block(  testfile, nelems, niters, seed, use_mmap)
    def test_random_seek_and_read(  testfile, nelems, niters, seed):           ctest_zran.test_random_seek_and_read(  testfile, nelems, niters, seed)
    @pytest.mark.slow_test
    def test_read_all_sequential(   testfile, nelems):                         ctest_zran.test_read_all_sequential(   testfile, nelems)
    @pytest.mark.slow_test
    def test_build_then_read(       testfile, nelems, seed, use_mmap):         ctest_zran.test_build_then_read(       testfile, nelems, seed, use_mmap)
    @pytest.mark.slow_test
    def test_readbuf_spacing_sizes( testfile, nelems, niters, seed):           ctest_zran.test_readbuf_spacing_sizes( testfile, nelems, niters, seed)
    def test_export_then_import(    testfile):                                 ctest_zran.test_export_then_import(    testfile)
    def test_export_import_no_points():                                        ctest_zran.test_export_import_no_points()
