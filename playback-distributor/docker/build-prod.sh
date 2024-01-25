#!/bin/bash

# Builds a production image of the Playback Distributor module.
#
# Usage:
#
# ./playback-distributor/docker/build-prod.sh [... extra args to pass to docker build command]
#

# NOTE: Ideally should be run from project root so that docker can copy over files
# shared across the various containers and images (e.g. anesowa_root/lib/c/common). If
# not run from root we protect the script by finding the root as follows.
ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/playback-distributor.*||')
ANESOWA_VERSION=${ANESOWA_VERSION:-prod}

set -x # Print commands as they run.

docker build \
  --build-arg "DEBUG=0" \
  --build-arg "DEPENDENCIES_COMPILE_FROM_SOURCE=1" \
  --tag anesowa/playback-distributor:$ANESOWA_VERSION \
  --file $ANESOWA_ROOT/playback-distributor/Dockerfile \
  --target production \
  $(echo $@) \
  $ANESOWA_ROOT

set +x
