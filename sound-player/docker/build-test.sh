#!/bin/bash

# Builds an image of the Sound Player module to run the tests.
#
# NOTE: Should be run from project root ideally.
#
# Usage:
#
# ./sound-player/docker/build-test.sh [... extra args to pass to docker build command]
#

ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/sound-player.*||')

set -x # Print commands as they run.

docker build \
	--build-arg DEBUG=0 \
	--tag anesowa/sound-player:test \
	--file $ANESOWA_ROOT/sound-player/Dockerfile \
	--target test \
	$(echo $@) \
	$ANESOWA_ROOT

set +x
