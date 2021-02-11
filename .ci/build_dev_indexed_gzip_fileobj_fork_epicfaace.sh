#!/usr/bin/env bash
#
# Build a test version of indexed_gzip_fileobj_fork_epicfaace.

set -e

envdir="$1"
thisdir=$(cd $(dirname "$0") && pwd)

source $thisdir/activate_env.sh "$envdir"

# enable line tracing for cython
# modules - see setup.py
export INDEXED_GZIP_TESTING=1

python setup.py develop
