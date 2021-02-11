#!/usr/bin/env bash
#
# Builds a binary wheel for indexed_gzip_fileobj_fork_epicfaace

set -e

envdir="$1"
thisdir=$(cd $(dirname "$0") && pwd)

source $thisdir/activate_env.sh "$envdir"

pip install twine

python setup.py bdist_wheel

twine check dist/*
