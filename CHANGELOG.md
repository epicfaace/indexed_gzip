# `indexed_gzip_fileobj_fork_epicfaace` changelog


## 1.4.0 (January 2nd 2021)


* Fixed a bug in the pickling/copying logic in the `IndexedGzipFile` class
  (#50, #51)
* New `indexed_gzip_fileobj_fork_epicfaace.open` function, which just creates and returns an
  `IndexedGzipFile`.
* When creating an `IndexedGzipFile`, the first argument (`filename`) may
  be either a file name, or an open file handle (#49, #53).
* Migrated CI testing and building to Github Actions (#52).
* Binary wheels for Windows now have ZLIB statically compiled in as part
  of the wheel, so ZLIB no longer needs to be installed (#43, #52).


## 1.3.3 (November 14th 2020)


* Adjusted the `ZranError` exception type to sub-class from `IOError`, to
  ease support for `nibabel`.
* Fixed a bug related to concatenated GZIP files which would occur when
  the read buffer ran out of space at the point where a stream boundary
  occurred.


## 1.3.2 (June 30th 2020)


* Adjusted the `NoHandleError` and `NotCoveredError` types to sub-class from
  `ValueError`, to preserve backwards compatibility with older versions of
  `nibabel`.


## 1.3.1 (June 25th 2020)


* Reverted the error type raised by the `IndexedGzipFile.seek` to `ValueError`,
  as `nibabel` assumes that the `seek` method of file objects raise a
  `ValueError` if `SEEK_END` is not supported.


## 1.3.0 (June 24th 2020)


* The `IndexedGzipFile.seek` method now accepts seeking from the end of
  uncompressed stream via `SEEK_END`, as long as the index has been built (#37).


## 1.2.0 (May 12th 2020)


* New `IndexedGzipFile.seek_points` method, which returns the compressed and
  uncompressed seek point locations.


## 1.1.0 (April 20th 2020)


* `IndexedGzipFile` objects are now picklable, as long as they are created with
  the default setting of `drop_handles=True` and with a `filename` and not an
  open `fileobj` (#28, #31).
* Changed the return type of `zran_tell` from `long` to `uint64_t`, because the
  former is not guaranteed to be 64 bit (#29, #30).
* Changed the `zran_index_t.compressed_size` and `uncompressed_size` fields from
  `size_t` to `uint64_t` because the former is not guaranteed to be 64 bit.


## 1.0.0 (February 21st 2020)


* Removed the deprecated `fid` argument to the `IndexedGzipFile` constructor.
* Removed the `SafeIndexedGzipFile`.


## 0.8.10 (May 15th 2019)


* Fix to package metadata.


## 0.8.9 (May 14th 2019)


* The `IndexedGzipFile.import_index` method and `zran_import_index` function
  can handle index files which do not contain any index points (#18).


## 0.8.8 (November 22nd 2018)

* Fixed bug affecting files which were an exact multiple of the read buffer
  size (#15).


## 0.8.7 (August 3rd 2018)

* Internal changes to how file handles are managed, to improve Windows
  compatibility.
* The `_IndexedGzipFile.read` method now acquires a single file handle, rather
  than opening/closing multiple handles across calls to `zran_read`.


## 0.8.6 (June 27th 2018)

* Workaround for issues with Python 2.7 and Cython < 0.26 (#10).


## 0.8.5 (June 16th 2018)

* Minor changes to packging.


## 0.8.4 (June 11th 2018)

* Removed `pytest-runner` as a dependency.


## 0.8.3 (June 11th 2018)

* Bugfix - variious methods and attributes were missing from the
  `IndexedGzipFile` wrapper class (#9).


## 0.8.2 (March 30th 2018)

Changes in this release:

* Bugfix in deprecated `SafeIndexedGzipFile`.


## 0.8.1 (March 24th 2018)

Changes in this release:

* Updated conda metadata.


## 0.8.0 (March 24th 2018)

Changes in this release:

* Added ability to import/export the index, via new `import_index` and
  `export_index` methods on the `IndexedGzipFile` class (#7, #8) - thanks
  @ozars !
* Deprecated `SafeIndexedGzipFile` - the `IndexedGzipFile` is now
  thread-safe, and has a read buffer. If you don't want buffering
  or thread-safety, use the `_IndexedGzipFile` class.
* Fixed bug in `seek` method - was not working with negative offsets.
* More unit tests, and code coverage of `.py` and `.pyx` files.


## 0.7.1 (March 5th 2018)

Changes in this release:

* Added `.conda/meta.yaml` file for building conda packages


## 0.7.0 (November 3rd 2017)

Changes in this release:

* `IndexedGzipFile.__init__` has a new option, `drop_handles` which causes an
  `IndexedGzipFile` to close/re-open the underlying file handle on every
  access (#5, #6). This has no impact on performance (as measured by the new
  benchmark script), so is enabled by default.

* New simpler benchmark script.

* Deprecated the `fid` parameter to `IndexedGzipFile.__init__` in favour of
  `fileobj` - another change to make `IndexedGzipFile` more similar to
  `gzip.GzipFile`.


## 0.6.1 (October 4th 2017)

Changes in this release:

* `IndexedGzipFile` now has a `readinto` method.
* `SafeIndexedGzipFile` is now an `io.BufferedReader`, which provides thread
  safety and dramatically improves performance for small files (see discussion
  at nipy/nibabel#558).
* Fixed issue #4 - the source distribution was missing `zran.h`.


## 0.6.0 (September 24th 2017)

Changes in this release:

* Preliminary support for Windows platforms (#1, #3) Thanks to @mcraig-ibme
  and @Trigonometry !

* Added `mode` attribute to `IndexedGzipFile`.


## 0.5.1 (September 12th 2017)

Changes in this release:

* Unit tests are run on a 32 bit platform
* The `indexed_gzip_fileobj_fork_epicfaace` package now has a `__version__` attribute


## 0.5.0 (September 8th 2017)

Changes in this release:

* Re-arranged code layout - there is now a top level `indexed_gzip_fileobj_fork_epicfaace` package,
  which contains the `indexed_gzip_fileobj_fork_epicfaace` module, and the `tests` package. Done so
  that tests can be distributed properly. No API changes though.

* `zran_seek` input parameter types made more specific due to an issue on 32 bit
  platforms.


## 0.4.1 (September 6th 2017)

Changes in this release:

* A tiny adjustment to unit test management allowing tests to be run from a
  different directory


## 0.4.0 (September 5th 2017)

Changes in this release involve modifications and additions to the
`IndexedGzipFile` class to make it look and behave more like the built-in
`gzip.GzipFile` class.

* `__init__` accepts `filename` and `mode` as its first two parameters

* Changed default values for `__init__` parameters to values which have been
  qualitatively tested

* `readline`, `readlines`, `__iter__` and `__next__` methods added, for
  iteration over lines in text data

* `seek` method accepts a `whence` parameter, and allows seeking from
  `SEEK_SET` or `SEEK_CUR`,


## 0.3.3 (May 3rd 2017)

Changes in this release:

* `SafeIndexedGzipFile` was broken under python 3.


## 0.3.2 (May 1st 2017)

Changes in this release:

* Bugfix (PR #2)


## 0.3.1 (October 17th 2016)

Changes in this release:

* One critical, silly bugfix that should have been in 0.3.


## 0.3 (October 16th 2016)

Changes in this release:

* Support for reading > 2**32 bytes in a single call.
* Support for concatenated gzip streams.
* Many related bug fixes.
* `zran.c` refactored so it is much cleaner and clearer.
* Test suite is much more comprehensive


## 0.2 (August 31st 2016)

The following changes have been made in this release:

* `indexed_gzip_fileobj_fork_epicfaace` now releases the GIL when possible
* A new `SafeIndexedGzipFile` class provides simple thread-safe file access to
  compressed files.
* Some initial test coverage using https://travis-ci.org
* Some important bug fixes.


## 0.1 (June 16th 2016)

* First seemingly stable release.
