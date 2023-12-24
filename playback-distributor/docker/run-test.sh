#!/bin/bash

# Runs container of the Playback Distributor module that runs the tests.
#
# NOTE: Should be run from project root ideally.
#
# Usage:
#
# ./playback-distributor/docker/run-test.sh [... extra args to pass to docker run command]
#

ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/playback-distributor.*||')

if [ "$(uname)" == "Linux" ]; then
  extra_flags=--add-host=host.docker.internal:host-gateway
else
  extra_flags=""
fi


set -x # Print commands as they run.

docker run \
  --rm \
  --tty \
  --interactive \
  --volume $ANESOWA_ROOT/playback-distributor/src:/anesowa/playback-distributor/src \
  --volume $ANESOWA_ROOT/playback-distributor/test:/anesowa/playback-distributor/test \
  --volume $ANESOWA_ROOT/recordings:/anesowa/recordings:ro \
  $extra_flags \
  $(echo $@) \
  anesowa/playback-distributor:test

set +x
