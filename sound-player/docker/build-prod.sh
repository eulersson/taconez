#!/bin/bash

# Builds a production image of the Sound Player module.
#
# Intended for local container development mainly.
#
# NOTE: Should be run from project root ideally.
#
# Usage:
#
# ./sound-player/docker/build-prod.sh [... extra args to pass to docker build command]
#

ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/sound-player.*||')

set -x # Print commands as they run.

docker build \
	--build-arg DEBUG=0 \
	--tag anesowa/sound-player:prod \
	--file $ANESOWA_ROOT/sound-player/Dockerfile \
	--target production \
	$(echo $@) \
	$ANESOWA_ROOT

set +x
