#!/bin/bash

# Runs container of the Sound Player module that runs the tests.
#
# Usage:
#
# ./sound-player/docker/run-test.sh [... extra args to pass to docker run command]
#

# NOTE: Ideally should be run from project root so that docker can copy over files
# shared across the various containers and images (e.g. anesowa_root/lib/c/common). If
# not run from root we protect the script by finding the root as follows.
ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/sound-player.*||')

ENTRYPOINT="$1"
entrypoint=""
if [ "$ENTRYPOINT" ]; then
	entrypoint="--entrypoint $ENTRYPOINT"
fi

if [ "$(uname)" == "Linux" ]; then
	extra_flags=--add-host=host.docker.internal:host-gateway
else
	extra_flags=""
fi

set -x # Print commands as they run.

docker run \
	--rm \
	--tty \
	--interactive \
	--volume $ANESOWA_ROOT/sound-player/src:/anesowa/sound-player/src \
	--volume $ANESOWA_ROOT/sound-player/CMakeLists.txt:/anesowa/sound-player/CMakeLists.txt \
	--volume $ANESOWA_ROOT/sound-player/tests:/anesowa/sound-player/tests \
	--volume $ANESOWA_ROOT/lib/c/commons/CMakeLists.txt:/anesowa/lib/c/commons/CMakeLists.txt \
	--volume $ANESOWA_ROOT/lib/c/commons/tests:/anesowa/lib/c/commons/tests \
	--volume $ANESOWA_ROOT/recordings:/anesowa/recordings:ro \
	$entrypoint \
	$extra_flags \
	anesowa/sound-player:test

set +x
