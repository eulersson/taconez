#!/bin/bash

# Runs a production container of the Sound Player module.
#
# This script will be launched by the Raspberry Pi systemd service's ExecStart:
#
# - sound-player/service/anesowa-sound-player.service
# - sound-player/service/exec-start.sh
#
# You can also launch it from the local machine instead too for debugging purposes.

ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/sound-detector.*||')

# If launched by the systemd service these two variables will be set.
ANESOWA_CONTAINER_NAME=${ANESOWA_CONTAINER_NAME:-anesowa-sound-player}
ANESOWA_VERSION=${ANESOWA_VERSION:-prod}

if [ "$(uname)" == "Linux" ]; then
  extra_flags="--add-host=host.docker.internal:host-gateway"
else
  extra_flags=""
fi

# Useful for seeing the actual command that's run on the service logs.
set -x;

docker run \
  --tty \
  --publish 5555:5555 \
  --publish 5556:5556 \
  --name $ANESOWA_CONTAINER_NAME \
  $extra_flags \
  anesowa/sound-player:$ANESOWA_VERSION

set +x;
