#!/bin/bash

# Builds a production image of the Sound Detector module.
#
# Intended for local container development mainly.
#
# NOTE: Should be run from project root ideally.
#
# Usage:
#
# ./playback-distributor/docker/build-prod.sh [... extra args to pass to docker build command]
#

ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/playback-distributor.*||')

docker build \
	--build-arg DEBUG=0 \
	--tag anesowa/playback-distributor:prod \
	--file $ANESOWA_ROOT/playback-distributor/Dockerfile \
	--target production \
	$ANESOWA_ROOT
