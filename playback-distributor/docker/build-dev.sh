#!/bin/bash

# Builds a development image of the Playback Distributor module.
#
# Intended for local container development mainly.
#
# NOTE: Should be run from project root ideally.
#
# Usage:
#
# ./playback-distributor/docker/build-dev.sh [... extra args to pass to docker build command]
#

ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/playback-distributor.*||')

set -x # Print commands as they run.

docker build \
	--build-arg DEBUG=1 \
	--tag anesowa/playback-distributor:dev \
	--file $ANESOWA_ROOT/playback-distributor/Dockerfile \
	--target development \
	$(echo $@) \
	$ANESOWA_ROOT

set +x
