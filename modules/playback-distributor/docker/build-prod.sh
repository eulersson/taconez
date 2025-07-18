#!/bin/bash

# Builds a production image of the Playback Distributor module.
#
# Usage:
#
# ./playback-distributor/docker/build-prod.sh [... extra args to pass to docker build command]
#

# NOTE: Ideally should be run from project root so that docker can copy over files
# shared across the various containers and images (e.g. taconez_root/lib/c/common). If
# not run from root we protect the script by finding the root as follows.
TACONEZ_ROOT=$(echo $(realpath $0) | sed 's|/modules/playback-distributor.*||')
TACONEZ_VERSION=${TACONEZ_VERSION:-prod}

set -x # Print commands as they run.

docker build \
  --build-arg "DEBUG=0" \
  --build-arg "DEPENDENCIES_COMPILE_FROM_SOURCE=1" \
  --tag taconez/playback-distributor:$TACONEZ_VERSION \
  --file $TACONEZ_ROOT/modules/playback-distributor/Dockerfile \
  --target production \
  $(echo $@) \
  $TACONEZ_ROOT

set +x
