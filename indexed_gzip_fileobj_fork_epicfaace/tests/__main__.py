#!/usr/bin/env python
#
# Author: Paul McCarthy <pauldmccarthy@gmail.com>
#
"""
Run indexed_gzip_fileobj_fork_epicfaace unit tests.  Requires pytest to be installed.


Works around a problem with pytest not discovring/running conftest.py files
when running tests that have been installed into the environment via the
--pyargs option.

https://github.com/pytest-dev/pytest/issues/1596

https://stackoverflow.com/questions/41270604/using-command-line-parameters-with-pytest-pyargs/43747114#43747114
"""


import os.path as op
import            sys


def main():
    import pytest

    testdir = op.abspath(op.dirname(__file__))

    sys.exit(pytest.main([testdir] + sys.argv[1:]))


if __name__ == '__main__':
    main()
