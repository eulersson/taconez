#!/bin/bash

# Runs a development container of the Sound Detector module.
#
# Intended for local container development mainly.

# Useful for seeing the actual command that's run on the service logs.
set -x

ENTRYPOINT="$1"

TACONEZ_ROOT=$(echo $(realpath $0) | sed 's|/sound-detector.*||')
PULSEAUDIO_COOKIE=${PULSEAUDIO_COOKIE:-$HOME/.config/pulse/cookie}

extra_flags=""
if [ "$(uname)" == "Linux" ]; then
  extra_flags="--add-host=host.docker.internal:host-gateway"
fi

entrypoint=""
if [ "$ENTRYPOINT" ]; then
  entrypoint="--entrypoint $ENTRYPOINT"
fi

docker run --rm --tty --interactive \
  --env INFLUX_DB_HOST=host.docker.internal \
  --env INFLUX_DB_TOKEN=no_token \
  --env PLAYBACK_DISTRIBUTOR_HOST=host.docker.internal \
  --env PULSE_SERVER=host.docker.internal \
  --env SKIP_DETECTION_NOTIFICATION=False \
  --env SKIP_RECORDING=False \
  --volume $PULSEAUDIO_COOKIE:/root/.config/pulse/cookie \
  --volume $TACONEZ_ROOT/sound-detector:/app/sound-detector \
  --volume $TACONEZ_ROOT/prerolls:/app/prerolls \
  --volume $TACONEZ_ROOT/recordings:/app/recordings \
  $extra_flags \
  $entrypoint \
  taconez/sound-detector:dev

set +x
