#!/bin/bash

# Builds an image of the Journal module to run the tests.
#
# Usage:
#
# ./modules/journal/docker/build-test.sh [... extra args to pass to docker build command]
#

# NOTE: Ideally should be run from project root so that docker can copy over files
# shared across the various containers and images (e.g. taconez_root/lib/c/common). If
# not run from root we protect the script by finding the root as follows.
TACONEZ_ROOT=$(echo $(realpath $0) | sed 's|/modules/journal.*||')

set -x # Print commands as they run.

docker build \
  --tag taconez/journal:test \
  --file $TACONEZ_ROOT/modules/journal/Dockerfile \
  --target test \
  $(echo $@) \
  $TACONEZ_ROOT

set +x
