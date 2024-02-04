#!/bin/bash

# Runs a production container of the Playback Distributor module.
#
# This script will be launched by the Raspberry Pi systemd service's ExecStart:
#
# - playback-distributor/service/taconez-playback-distributor.service
# - playback-distributor/service/exec-start.sh
#
# You can also launch it from the local machine instead too for debugging purposes.
#
# Usage:
#
# ./playback-distributor/docker/run-prod.sh [... extra args to pass to docker run command]
#

# NOTE: Ideally should be run from project root so that docker can copy over files
# shared across the various containers and images (e.g. taconez_root/lib/c/common). If
# not run from root we protect the script by finding the root as follows.
TACONEZ_ROOT=$(echo $(realpath $0) | sed 's|/playback-distributor.*||')

# If launched by the systemd service these two variables will be set.
TACONEZ_CONTAINER_NAME=${TACONEZ_CONTAINER_NAME:-taconez-playback-distributor}
TACONEZ_VERSION=${TACONEZ_VERSION:-prod}

if [ "$(uname)" == "Linux" ]; then
  extra_flags="--add-host=host.docker.internal:host-gateway"
else
  extra_flags=""
fi

set -x # Print commands as they run.

docker run \
  --tty \
  --volume /mnt/nfs/taconez:/app/recordings:ro \
  --volume $TACONEZ_ROOT/prerolls:/app/prerolls:ro \
  --name $TACONEZ_CONTAINER_NAME \
  --publish 5555:5555 \
  --publish 5556:5556 \
  $extra_flags \
  taconez/playback-distributor:$TACONEZ_VERSION

set +x
