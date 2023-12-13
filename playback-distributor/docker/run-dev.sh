#!/bin/bash

# Runs a development container of the Sound Player module.
#
# Intended for local container development mainly.

if [ "$(uname)" == "Darwin" ]; then
    ANESOWA_PROJECT_ROOT=${ANESOWA_PROJECT_ROOT:-$HOME/Devel/anesowa}
    docker run --rm --tty --interactive \
      --env PULSE_SERVER=host.docker.internal \
      --volume $HOME/.config/pulse/cookie:/root/.config/pulse/cookie \
      --volume $ANESOWA_PROJECT_ROOT/sound-player:/anesowa/sound-player \
      anesowa/sound-detector:dev sh
elif [ "$(uname)" == "Linux" ]; then
    ANESOWA_PROJECT_ROOT=${ANESOWA_PROJECT_ROOT:-$HOME}
    docker run --rm --tty --interactive \
      --add-host=host.docker.internal:host-gateway \
      --env PULSE_SERVER=host.docker.internal \
      --volume $HOME/.config/pulse/cookie:/root/.config/pulse/cookie \
      --volume $ANESOWA_PROJECT_ROOT/sound-detector:/anesowa/sound-detector \
      anesowa/sound-detector:dev sh
fi
