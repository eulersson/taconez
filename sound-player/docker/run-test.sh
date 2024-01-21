#!/bin/bash

# Runs the tests of the Playback Distributor module.
#
# Usage:
#
# ./sound-player/docker/run-test.sh [--with-dependency-tests]
#

# Default value
RUN_DEPENDENCY_TESTS=0

# Check for --with-dependency-tests flag
for arg in "$@"
do
    if [ "$arg" == "--with-dependency-tests" ]
    then
        RUN_DEPENDENCY_TESTS=1
        break
    fi
done

set -x # Print commands as they run.

docker run \
  --rm \
  --tty \
  --interactive \
  -e RUN_DEPENDENCY_TESTS=$RUN_DEPENDENCY_TESTS \
  anesowa/sound-player:test
set +x
