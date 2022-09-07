#!/usr/bin/env bash

set -e

# Make sure zlib headers are available on linux
export CIBW_BEFORE_ALL_LINUX="yum install -y zlib-devel || apt-get install -y zlib1g-dev || apk add zlib-dev || true"

# ZLIB is compiled into indexed_gzip_fileobj_fork_epicfaace on windwos -
# see .ci/download_zlib.sh and setup.py
export CIBW_ENVIRONMENT_WINDOWS="ZLIB_HOME='$ZLIB_HOME'"

# Run quick test suite on built wheels.
export CIBW_TEST_REQUIRES="cython pytest numpy nibabel"

# Disable pypy builds (reasons for doing this have been lost to
# history [GHA logs of failing builds deleted]).
#
# Disable musllinux builds until numpy binaries are available (as
# compiling numpy takes too long, and causes GHA jobs to time out).
export CIBW_SKIP="pp* *musllinux* cp27* cp35*"

# Skip i686/aarch64 tests - I have experienced hangs on these
# platforms, which I traced to a trivial numpy operation -
# "numpy.linalg.det(numpy.eye(3))". This occurs when numpy has
# to be compiled from source during the build, so can be
# re-visited if/when numpy is avaialble on all platforms.
export CIBW_TEST_SKIP="*i686* *aarch64*"

# Pytest makes it *very* awkward to run tests
# from an installed package, and still find/
# interpret a conftest.py file correctly.
echo '#!/usr/bin/env bash'                                               >  testcmd
echo 'cp $1/pyproject.toml .'                                            >> testcmd
echo 'python -m indexed_gzip_fileobj_fork_epicfaace.tests -c pyproject.toml -m "not slow_test"' >> testcmd
chmod a+x testcmd

export CIBW_TEST_COMMAND="bash {project}/testcmd {project}"

# cibuildwheel 2 doesn't support py27, but cibuildwheel
# 1 doesn't suppport py310. So we do two builds.
python -m pip install cibuildwheel
python -m cibuildwheel --output-dir ./dist

# Disable py27 builds
export CIBW_BUILD=""
python -m pip install cibuildwheel==1.*
python -m cibuildwheel --allow-empty --output-dir ./dist
