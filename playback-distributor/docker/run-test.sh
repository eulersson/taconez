#!/bin/bash

# Runs the tests of the Playback Distributor module.
#
# Usage:
#
# ./playback-distributor/docker/run-test.sh [... extra args to pass to docker run command]
#

# NOTE: Ideally should be run from project root so that docker can copy over files
# shared across the various containers and images (e.g. anesowa_root/lib/c/common). If
# not run from root we protect the script by finding the root as follows.
ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/playback-distributor.*||')

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
