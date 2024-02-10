#!/bin/bash

# Builds a production image of the Journal module.
#
# Usage:
#
# ./journal/docker/build-prod.sh [... extra args to pass to docker build command]
#

# NOTE: Ideally should be run from project root so that docker can copy over files
# shared across the various containers and images (e.g. taconez_root/lib/c/common). If
# not run from root we protect the script by finding the root as follows.
TACONEZ_ROOT=$(echo $(realpath $0) | sed 's|/journal.*||')
TACONEZ_VERSION=${TACONEZ_VERSION:-prod}

set -x # Print commands as they run.

docker build \
  --tag taconez/journal:$TACONEZ_VERSION \
  --file $TACONEZ_ROOT/journal/Dockerfile \
  --target production \
  $(echo $@) \
  $TACONEZ_ROOT

set +x
