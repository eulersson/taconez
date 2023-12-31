#!/bin/bash

# Runs the tests of the Playback Distributor module.
#
# Intended for local container development mainly.
#
# NOTE: Should be run from project root ideally.
#
# Usage:
#
# ./playback-distributor/docker/run-test.sh [... extra args to pass to docker run command]
#

ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/playback-distributor.*||')

ENTRYPOINT="$1"

entrypoint=""
if [ "$ENTRYPOINT" ]; then
	entrypoint="--entrypoint $ENTRYPOINT"
fi

set -x # Print commands as they run.

docker run \
	--rm \
	--tty \
	--interactive \
	--volume $ANESOWA_ROOT/playback-distributor/src:/anesowa/playback-distributor/src \
	--volume $ANESOWA_ROOT/playback-distributor/CMakeLists.txt:/anesowa/playback-distributor/CMakeLists.txt \
	--volume $ANESOWA_ROOT/playback-distributor/tests:/anesowa/playback-distributor/tests \
	$entrypoint \
	anesowa/playback-distributor:test

set +x
