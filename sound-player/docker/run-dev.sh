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
# shared across the various containers and images (e.g. taconez_root/lib/c/common). If
# not run from root we protect the script by finding the root as follows.
TACONEZ_ROOT=$(echo $(realpath $0) | sed 's|/sound-player.*||')

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

PULSEAUDIO_COOKIE=${PULSEAUDIO_COOKIE:-$HOME/.config/pulse/cookie}

set -x # Print commands as they run.

docker run \
  --rm \
  --tty \
  --interactive \
  --env PULSE_SERVER=host.docker.internal \
  --env PLAYBACK_DISTRIBUTOR_HOST=host.docker.internal \
  --volume $TACONEZ_ROOT/sound-player/src:/app/sound-player/src \
  --volume $TACONEZ_ROOT/sound-player/CMakeLists.txt:/app/sound-player/CMakeLists.txt \
  --volume $TACONEZ_ROOT/sound-player/tests:/app/sound-player/tests \
  --volume $TACONEZ_ROOT/lib/c/commons/CMakeLists.txt:/app/lib/c/commons/CMakeLists.txt \
  --volume $TACONEZ_ROOT/prerolls:/app/prerolls:ro \
  --volume $TACONEZ_ROOT/recordings:/app/recordings:ro \
  --volume $PULSEAUDIO_COOKIE:/root/.config/pulse/cookie \
  $extra_flags \
  $entrypoint \
  taconez/sound-player:dev

set +x
