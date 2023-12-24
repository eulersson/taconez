#!/bin/bash

# Runs container of the Sound Player module that runs the tests.
#
# NOTE: Should be run from project root ideally.
#
# Usage:
#
# ./sound-player/docker/run-test.sh [... extra args to pass to docker run command]
#

ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/sound-player.*||')

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
  --volume $ANESOWA_ROOT/sound-player/src:/anesowa/sound-player/src \
  --volume $ANESOWA_ROOT/sound-player/test:/anesowa/sound-player/test \
  --volume $ANESOWA_ROOT/recordings:/anesowa/recordings:ro \
  $extra_flags \
  $(echo $@) \
  anesowa/sound-player:test

set +x
