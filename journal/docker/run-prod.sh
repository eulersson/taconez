#!/bin/bash

# Runs a production container of the Journal module.
#
# This script will be launched by the Raspberry Pi systemd service's ExecStart:
#
# - journal/service/taconez-journal.service
# - journal/service/exec-start.sh
#
# You can also launch it from the local machine instead too for debugging purposes.
#
# Usage:
#
# ./journal/docker/run-prod.sh [... extra args to pass to docker run command]
#

# NOTE: Ideally should be run from project root so that docker can copy over files
# shared across the various containers and images (e.g. taconez_root/lib/c/common). If
# not run from root we protect the script by finding the root as follows.
TACONEZ_ROOT=$(echo $(realpath $0) | sed 's|/journal.*||')

# If launched by the systemd service these two variables will be set.
TACONEZ_CONTAINER_NAME=${TACONEZ_CONTAINER_NAME:-taconez-journal}
TACONEZ_VERSION=${TACONEZ_VERSION:-prod}
PLAYBACK_DISTRIBUTOR_HOST=${PLAYBACK_DISTRIBUTOR_HOST:-host.docker.internal}

if [ "$(uname)" == "Linux" ]; then
  extra_flags="--add-host=host.docker.internal:host-gateway"
else
  extra_flags=""
fi

PULSEAUDIO_COOKIE=${PULSEAUDIO_COOKIE:-$HOME/.config/pulse/cookie}

set -x # Print commands as they run.

# Host network, dbus and avahi-daemon are needed for mDNS resolution.
# 
#   https://www.reddit.com/r/AlpineLinux/comments/14kmoot/comment/jubgt0j/
#
docker run \
  --name $TACONEZ_CONTAINER_NAME \
  --tty \
  --env PLAYBACK_DISTRIBUTOR_HOST=$PLAYBACK_DISTRIBUTOR_HOST \
  --volume /mnt/nfs/taconez:/app/recordings:ro \
  --volume $TACONEZ_ROOT/prerolls:/app/prerolls:ro \
  --volume /var/run/dbus:/var/run/dbus \
  --volume /var/run/avahi-daemon/socket:/var/run/avahi-daemon/socket \
  $extra_flags \
  taconez/journal:$TACONEZ_VERSION

set +x
