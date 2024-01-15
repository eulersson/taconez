#!/bin/bash

# Runs a production container of the Playback Distributor module.
#
# This script will be launched by the Raspberry Pi systemd service's ExecStart:
#
# - playback-distributor/service/anesowa-playback-distributor.service
# - playback-distributor/service/exec-start.sh
#
# You can also launch it from the local machine instead too for debugging purposes.
#
# Usage:
#
# ./playback-distributor/docker/run-prod.sh [... extra args to pass to docker run command]
#

# NOTE: Ideally should be run from project root so that docker can copy over files
# shared across the various containers and images (e.g. anesowa_root/lib/c/common). If
# not run from root we protect the script by finding the root as follows.
ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/sound-detector.*||')

# If launched by the systemd service these two variables will be set.
ANESOWA_CONTAINER_NAME=${ANESOWA_CONTAINER_NAME:-anesowa-playback-distributor}
ANESOWA_VERSION=${ANESOWA_VERSION:-prod}

if [ "$(uname)" == "Linux" ]; then
  extra_flags="--add-host=host.docker.internal:host-gateway"
else
  extra_flags=""
fi

set -x # Print commands as they run.

docker run \
  --tty \
  --name $ANESOWA_CONTAINER_NAME \
  --volume $ANESOWA_ROOT/recordings:/anesowa/recordings:ro \
  --volume $ANESOWA_ROOT/prerolls:/anesowa/prerolls:ro \
  $extra_flags \
  anesowa/playback-distributor:$ANESOWA_VERSION

set +x
