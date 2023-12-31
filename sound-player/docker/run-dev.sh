#!/bin/bash

# Runs a development container of the Playback Distributor module.
#
# Intended for local container development mainly.
#
# NOTE: Should be run from project root ideally.
#
# Usage:
#
# ./playback-distributor/docker/run-dev.sh [... extra args to pass to docker run command]
#

ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/sound-player.*||')

ENTRYPOINT="$1"

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
	--volume $ANESOWA_ROOT/sound-player/src:/anesowa/sound-player/src \
	--volume $ANESOWA_ROOT/sound-player/CMakeLists.txt:/anesowa/sound-player/CMakeLists.txt \
	--volume $ANESOWA_ROOT/sound-player/tests:/anesowa/sound-player/tests \
	--volume $ANESOWA_ROOT/lib/c/commons/CMakeLists.txt:/anesowa/lib/c/commons/CMakeLists.txt \
	--volume $ANESOWA_ROOT/recordings:/anesowa/recordings:ro \
	$extra_flags \
	$entrypoint \
	anesowa/sound-player:dev

set +x
