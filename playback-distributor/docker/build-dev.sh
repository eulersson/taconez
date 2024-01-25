#!/bin/bash

# Builds a development image of the Playback Distributor module.
#
# Intended for local container development mainly.
#
# Usage:
#
# ./playback-distributor/docker/build-dev.sh [... extra args to pass to docker build command]
#
# NOTE: If you prefer you might want to use the docker compose set up for development.
#

# NOTE: Ideally should be run from project root so that docker can copy over files
# shared across the various containers and images (e.g. anesowa_root/lib/c/common). If
# not run from root we protect the script by finding the root as follows.
ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/playback-distributor.*||')

set -x # Print commands as they run.

docker build \
  --build-arg "DEBUG=1" \
  --build-arg "DEPENDENCIES_COMPILE_FROM_SOURCE=1" \
  --target development \
  --tag anesowa/playback-distributor:dev \
  --file $ANESOWA_ROOT/playback-distributor/Dockerfile \
  $(echo $@) \
  $ANESOWA_ROOT

set +x
