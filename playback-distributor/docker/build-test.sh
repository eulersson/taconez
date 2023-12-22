#!/bin/bash

# Builds an image of the Sound Detector module to run the tests.
#
# NOTE: Should be run from project root ideally.
#
# Usage:
#
# ./playback-distributor/docker/build-test.sh [... extra args to pass to docker build command]
#

ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/playback-distributor.*||')

set -x;
docker build \
	--build-arg DEBUG=0 \
	--tag anesowa/playback-distributor:test \
	--file $ANESOWA_ROOT/playback-distributor/Dockerfile \
	--target test \
  $(echo $@) \
	$ANESOWA_ROOT
set +x;
