#!/bin/bash

# Runs a development container of the Playback Distributor module.
#
# Intended for local container development mainly.
#
# NOTE: Should be run from project root ideally.
#
# Usage:
#
# ./playback-distributor/docker/run-test.sh [... extra args to pass to docker run command]
#

ENTRYPOINT="$1"

ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/playback-distributor.*||')

set -x # Print commands as they run.

docker run \
	--rm \
	--tty \
	--interactive \
	anesowa/playback-distributor:test

set +x
