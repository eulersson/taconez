#!/bin/bash

# Runs a development container of the Sound Detector module.
#
# Intended for local container development mainly.

if [ "$(uname)" == "Darwin" ]; then
    ANESOWA_PROJECT_ROOT=${ANESOWA_PROJECT_ROOT:-$HOME/Devel/anesowa}
    docker run --rm --tty --interactive \
      --env PULSE_SERVER=host.docker.internal \
      --env SKIP_RECORDING=True \
      --env SKIP_DETECTION_NOTIFICATION=True \
      --volume $HOME/.config/pulse/cookie:/root/.config/pulse/cookie \
      --volume $ANESOWA_PROJECT_ROOT/sound-detector:/anesowa/sound-detector \
      --name anesowa-sound-detector-dev \
      anesowa/sound-detector:dev
elif [ "$(uname)" == "Linux" ]; then
    ANESOWA_PROJECT_ROOT=${ANESOWA_PROJECT_ROOT:-$HOME}
    docker run --rm --tty --interactive \
      --add-host=host.docker.internal:host-gateway \
      --env PULSE_SERVER=host.docker.internal \
      --env SKIP_RECORDING=True \
      --env SKIP_DETECTION_NOTIFICATION=True \
      --volume $HOME/.config/pulse/cookie:/root/.config/pulse/cookie \
      --volume $ANESOWA_PROJECT_ROOT/sound-detector:/anesowa/sound-detector \
      --name anesowa-sound-detector-dev \
      anesowa/sound-detector:dev
fi
