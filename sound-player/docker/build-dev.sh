#!/bin/bash

# Builds a development image of the Sound Player module.
#
# Intended for local container development mainly.
#
# NOTE: Should be run from project root ideally.
#
# Usage:
#
# ./sound-player/docker/build-dev.sh [... extra args to pass to docker build command]
#

ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/sound-player.*||')

set -x # Print commands as they run.

docker build \
  --build-arg DEBUG=1 \
  --tag anesowa/sound-player:dev \
  --file $ANESOWA_ROOT/sound-player/Dockerfile \
  --target development \
  $ANESOWA_ROOT

set +x
