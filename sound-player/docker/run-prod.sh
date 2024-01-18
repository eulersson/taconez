#!/bin/bash

# Runs a production container of the Sound Player module.
#
# This script will be launched by the Raspberry Pi systemd service's ExecStart:
#
# - sound-player/service/anesowa-sound-player.service
# - sound-player/service/exec-start.sh
#
# You can also launch it from the local machine instead too for debugging purposes.
#
# Usage:
#
# ./sound-player/docker/run-prod.sh [... extra args to pass to docker run command]
#

# NOTE: Ideally should be run from project root so that docker can copy over files
# shared across the various containers and images (e.g. anesowa_root/lib/c/common). If
# not run from root we protect the script by finding the root as follows.
ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/sound-player.*||')

# If launched by the systemd service these two variables will be set.
ANESOWA_CONTAINER_NAME=${ANESOWA_CONTAINER_NAME:-anesowa-sound-player}
ANESOWA_VERSION=${ANESOWA_VERSION:-prod}

if [ "$(uname)" == "Linux" ]; then
	extra_flags="--add-host=host.docker.internal:host-gateway"
else
	extra_flags=""
fi

PULSEAUDIO_COOKIE=${PULSEAUDIO_COOKIE:-$HOME/.config/pulse/cookie}

set -x # Print commands as they run.

docker run \
	--tty \
	--name $ANESOWA_CONTAINER_NAME \
	--volume /mnt/nfs/anesowa:/app/recordings:ro \
	--volume $ANESOWA_ROOT/prerolls:/app/prerolls:ro \
	--env PULSE_SERVER=host.docker.internal \
	--volume $PULSEAUDIO_COOKIE:/root/.config/pulse/cookie \
	$extra_flags \
	anesowa/sound-player:$ANESOWA_VERSION

set +x
