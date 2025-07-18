#!/bin/bash

# Builds an image of the Sound Player module to run the tests.
#
# Usage:
#
# ./modules/sound-player/docker/build-test.sh [... extra args to pass to docker build command]
#

# NOTE: Ideally should be run from project root so that docker can copy over files
# shared across the various containers and images (e.g. taconez_root/lib/c/common). If
# not run from root we protect the script by finding the root as follows.
TACONEZ_ROOT=$(echo $(realpath $0) | sed 's|/modules/sound-player.*||')

set -x # Print commands as they run.

docker build \
  --build-arg DEBUG=0 \
  --tag taconez/sound-player:test \
  --file $TACONEZ_ROOT/modules/sound-player/Dockerfile \
  --target test \
  $(echo $@) \
  $TACONEZ_ROOT

set +x
