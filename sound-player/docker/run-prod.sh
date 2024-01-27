#!/bin/bash

# Runs a production container of the Sound Player module.
#
# This script will be launched by the Raspberry Pi systemd service's ExecStart:
#
# - sound-player/service/taconez-sound-player.service
# - sound-player/service/exec-start.sh
#
# You can also launch it from the local machine instead too for debugging purposes.
#
# Usage:
#
# ./sound-player/docker/run-prod.sh [... extra args to pass to docker run command]
#

# NOTE: Ideally should be run from project root so that docker can copy over files
# shared across the various containers and images (e.g. taconez_root/lib/c/common). If
# not run from root we protect the script by finding the root as follows.
TACONEZ_ROOT=$(echo $(realpath $0) | sed 's|/sound-player.*||')

# If launched by the systemd service these two variables will be set.
TACONEZ_CONTAINER_NAME=${TACONEZ_CONTAINER_NAME:-taconez-sound-player}
TACONEZ_VERSION=${TACONEZ_VERSION:-prod}
PLAYBACK_DISTRIBUTOR_HOST=${PLAYBACK_DISTRIBUTOR_HOST:-host.docker.internal}

if [ "$(uname)" == "Linux" ]; then
  extra_flags="--add-host=host.docker.internal:host-gateway"
else
  extra_flags=""
fi

PULSEAUDIO_COOKIE=${PULSEAUDIO_COOKIE:-$HOME/.config/pulse/cookie}

set -x # Print commands as they run.

docker run \
  --tty \
  --env PULSE_SERVER=host.docker.internal \
  --env PLAYBACK_DISTRIBUTOR_HOST=$PLAYBACK_DISTRIBUTOR_HOST \
  --volume /mnt/nfs/taconez:/app/recordings:ro \
  --volume $TACONEZ_ROOT/prerolls:/app/prerolls:ro \
  --volume $PULSEAUDIO_COOKIE:/root/.config/pulse/cookie \
  --name $TACONEZ_CONTAINER_NAME \
  $extra_flags \
  taconez/sound-player:$TACONEZ_VERSION

set +x
