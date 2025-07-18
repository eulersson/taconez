#!/bin/bash

# Runs a development container of the Journal module.
#
# Intended for local container development mainly.
#
# Usage:
#
# ./modules/journal/docker/run-dev.sh [... extra args to pass to docker run command]
#

# NOTE: Ideally should be run from project root so that docker can copy over files
# shared across the various containers and images (e.g. taconez_root/lib/c/common). If
# not run from root we protect the script by finding the root as follows.
TACONEZ_ROOT=$(echo $(realpath $0) | sed 's|/modules/journal.*||')

ENTRYPOINT="$1"
entrypoint=""
if [ "$ENTRYPOINT" ]; then
  entrypoint="--entrypoint $ENTRYPOINT"
fi

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
  --env INFLUX_DB_HOST=host.docker.internal \
  --env PLAYBACK_DISTRIBUTOR_HOST=host.docker.internal \
  --volume $TACONEZ_ROOT/prerolls:/app/prerolls:ro \
  --volume $TACONEZ_ROOT/recordings:/app/recordings:ro \
  $extra_flags \
  $entrypoint \
  taconez/journal:dev

set +x
