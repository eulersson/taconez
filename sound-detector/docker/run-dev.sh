#!/bin/bash

# Runs a development container of the Sound Detector module.
#
# Intended for local container development mainly.

# Useful for seeing the actual command that's run on the service logs.
set -x

COMMAND="$1"

ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/sound-detector.*||')
PULSEAUDIO_COOKIE=${PULSEAUDIO_COOKIE:-$HOME/.config/pulse/cookie}

extra_flags=""
if [ "$(uname)" == "Linux" ]; then
  extra_flags="--add-host=host.docker.internal:host-gateway"
fi

docker run --rm --tty --interactive \
  --env PULSE_SERVER=host.docker.internal \
  --env SKIP_RECORDING=True \
  --env SKIP_DETECTION_NOTIFICATION=True \
  --volume $PULSEAUDIO_COOKIE:/root/.config/pulse/cookie \
  --volume $ANESOWA_ROOT/sound-detector:/anesowa/sound-detector \
  $extra_flags \
  anesowa/sound-detector:dev \
  $COMMAND

set +x
