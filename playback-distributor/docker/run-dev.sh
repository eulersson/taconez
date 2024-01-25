#!/bin/bash

# Runs a development container of the Playback Distributor module.
#
# Intended for local container development mainly.
#
# Usage:
#
# ./playback-distributor/docker/run-dev.sh [... extra args to pass to docker run command]
#

# NOTE: Ideally should be run from project root so that docker can copy over files
# shared across the various containers and images (e.g. anesowa_root/lib/c/common). If
# not run from root we protect the script by finding the root as follows.
ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/playback-distributor.*||')

ENTRYPOINT="$1"
entrypoint=""
if [ "$ENTRYPOINT" ]; then
  entrypoint="--entrypoint $ENTRYPOINT"
fi

set -x # Print commands as they run.

docker run \
  --rm \
  --tty \
  --interactive \
  --volume $ANESOWA_ROOT/playback-distributor/src:/app/playback-distributor/src \
  --volume $ANESOWA_ROOT/playback-distributor/CMakeLists.txt:/app/playback-distributor/CMakeLists.txt \
  --volume $ANESOWA_ROOT/playback-distributor/tests:/app/playback-distributor/tests \
  --volume $ANESOWA_ROOT/lib/c/commons/CMakeLists.txt:/app/lib/c/commons/CMakeLists.txt \
  --volume $ANESOWA_ROOT/prerolls:/app/prerolls:ro \
  --volume $ANESOWA_ROOT/recordings:/app/recordings:ro \
  $entrypoint \
  anesowa/playback-distributor:dev

set +x
