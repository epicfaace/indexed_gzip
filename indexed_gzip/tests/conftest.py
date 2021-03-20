#!/usr/bin/env python
#
# conftest.py -
#
# Author: Paul McCarthy <pauldmccarthy@gmail.com>
#

import            os
import os.path as op
import numpy   as np

import pytest


def pytest_addoption(parser):

    parser.addoption('--nelems',
                     type=str,
                     action='store',
                     default='rnd_16777217',
                     help='Number of uint64 elements for test data')

    parser.addoption('--concat',
                     action='store_true',
                     help='Generate test data made of '
                          'concatenated GZIP streams')

    parser.addoption('--use_mmap',
                     action='store_true',
                     help='Use mmap for read buffer instead of main memory')

    parser.addoption('--seed',
                     type=int,
                     help='Seed for random number generator')

    parser.addoption('--testfile',
                     action='store',
                     help='Name of test file')

    parser.addoption('--niters',
                     type=int,
                     action='store',
                     default=1000,
                     help='Number of inputs for tests which '
                          'use a random set of inputs')

@pytest.fixture
def nelems(request):
    val = request.config.getoption('--nelems')
    if val.startswith('rnd_'):
        if hasattr(nelems, 'val'):
            val = nelems.val
        else:
            # val +/- 20%
            val        = int(val.split('_')[1])
            var        = (np.random.random() - 0.5) * val * 0.4
            val        = round(val + var)
            nelems.val = val

    return int(val)


@pytest.fixture
def niters(request):
    return request.config.getoption('--niters')


@pytest.fixture
def concat(request):
    return request.config.getoption('--concat')


@pytest.fixture
def use_mmap(request):
    return request.config.getoption('--use_mmap')

@pytest.fixture
def seed(request):

    seed = request.config.getoption('--seed')

    if seed is None:
        seed = np.random.randint(2 ** 30)

    np.random.seed(seed)
    print('Seed for random number generator: {}'.format(seed))
    return seed



@pytest.fixture
def testfile(request, nelems, concat):

    from indexed_gzip.tests import gen_test_data

    filename = request.config.getoption('--testfile')

    if filename is None:
        filename = op.join(os.getcwd(),
                           'ctest_zran_{}_{}.gz'.format(nelems, concat))

    if not op.exists(filename):
        gen_test_data(filename, nelems, concat)

    return filename
