#!/usr/bin/env python
#
# __init__.py - The indexed_gzip_fileobj_fork_epicfaace namespace.
#
# Author: Paul McCarthy <pauldmccarthy@gmail.com>
#
"""The indexed_gzip_fileobj_fork_epicfaace namespace. """


from .indexed_gzip_fileobj_fork_epicfaace import (_IndexedGzipFile,     # noqa
                           IndexedGzipFile,
                           open,
                           NotCoveredError,
                           NoHandleError,
                           ZranError)


SafeIndexedGzipFile = IndexedGzipFile
"""Alias for ``IndexedGzipFile``, to preserve compatibility with older
versions of ``nibabel``.
"""


__version__ = '1.4.1'
