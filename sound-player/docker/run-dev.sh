#!/bin/bash

# Runs a development container of the Sound Player module.
#
# Intended for local container development mainly.

ENTRYPOINT="$1"

ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/sound-player.*||')
PULSEAUDIO_COOKIE=${PULSEAUDIO_COOKIE:-$HOME/.config/pulse/cookie}

if [ "$(uname)" == "Linux" ]; then
  extra_flags=--add-host=host.docker.internal:host-gateway
else
  extra_flags=""
fi

entrypoint=""
if [ "$ENTRYPOINT" ]; then
  entrypoint="--entrypoint $ENTRYPOINT"
fi

set -x # Print commands as they run.

docker run \
  --rm \
  --tty \
  --interactive \
  --env PULSE_SERVER=host.docker.internal \
  --volume $PULSEAUDIO_COOKIE:/root/.config/pulse/cookie \
  --volume $ANESOWA_ROOT/sound-player:/anesowa/sound-player \
  --volume $ANESOWA_ROOT/recordings:/anesowa/recordings:ro \
  $extra_flags \
  $entrypoint \
  anesowa/sound-player:dev

set +x
