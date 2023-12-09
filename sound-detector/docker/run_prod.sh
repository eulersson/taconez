#!/bin/bash

# Runs a production container of the Sound Detector module.
#
# This script will be launched by the Raspberry Pi systemd service's ExecStart:
#
# - sound-detector/service/anesowa-sound-detector.service
# - sound-detector/service/exec-start.sh
#
# You can also launch it from the local machine instead too for debugging purposes.

# If launched by the systemd service these two variables will be set.
ANESOWA_CONTAINER_NAME=${ANESOWA_CONTAINER_NAME:-anesowa-sound-detector-prod}
ANESOWA_VERSION=${ANESOWA_VERSION:-prod}

if [ "$(uname)" == "Darwin" ]; then
    ANESOWA_PROJECT_ROOT=${ANESOWA_PROJECT_ROOT:-$HOME/Devel/anesowa}
    docker run --rm --tty \
      --env PULSE_SERVER=host.docker.internal \
      --volume $HOME/.config/pulse/cookie:/root/.config/pulse/cookie \
      --volume $ANESOWA_PROJECT_ROOT/recordings:/recordings \
      --name $ANESOWA_CONTAINER_NAME \
      anesowa/sound-detector:$ANESOWA_VERSION
elif [ "$(uname)" == "Linux" ]; then
    ANESOWA_PROJECT_ROOT=${ANESOWA_PROJECT_ROOT:-$HOME}
    # Useful for seeing the actual command that's run on the service logs.
    set -x;
    docker run --tty \
      --add-host=host.docker.internal:host-gateway \
      --env PULSE_SERVER=host.docker.internal \
      --volume /home/anesowa/.config/pulse/cookie:/root/.config/pulse/cookie \
      --volume /mnt/nfs/anesowa:/recordings \
      --name $ANESOWA_CONTAINER_NAME \
      anesowa/sound-detector:$ANESOWA_VERSION
    set +x;
fi
