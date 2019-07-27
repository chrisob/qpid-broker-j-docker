#!/usr/bin/env sh

set -o errexit
set -o nounset

export QPID_WORK="${HOME}"
export QPID_RUN_LOG=2

exec "$@"
