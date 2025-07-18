#!/bin/bash

# Runs a production container of the Journal module.
#
# This script will be launched by the Raspberry Pi systemd service's ExecStart:
#
# - modules/journal/service/taconez-journal.service
# - modules/journal/service/exec-start.sh
#
# You can also launch it from the local machine instead too for debugging purposes.
#
# Usage:
#
# ./modules/journal/docker/run-prod.sh [... extra args to pass to docker run command]
#

# NOTE: Ideally should be run from project root so that docker can copy over files
# shared across the various containers and images (e.g. taconez_root/lib/c/common). If
# not run from root we protect the script by finding the root as follows.
TACONEZ_ROOT=$(echo $(realpath $0) | sed 's|/modules/journal.*||')

# If launched by the systemd service these two variables will be set.
TACONEZ_CONTAINER_NAME=${TACONEZ_CONTAINER_NAME:-taconez-journal}
TACONEZ_VERSION=${TACONEZ_VERSION:-prod}

if [ "$(uname)" == "Linux" ]; then
	extra_flags="--add-host=host.docker.internal:host-gateway"
else
	extra_flags=""
fi

PULSEAUDIO_COOKIE=${PULSEAUDIO_COOKIE:-$HOME/.config/pulse/cookie}

# Check if PLAYBACK_DISTRIBUTOR_HOST is not an IPv4 address and not host.docker.internal
PLAYBACK_DISTRIBUTOR_HOST=${PLAYBACK_DISTRIBUTOR_HOST:-host.docker.internal}
is_ipv4=$(echo "$PLAYBACK_DISTRIBUTOR_HOST" | grep -cEo '^([0-9]{1,3}\.){3}[0-9]{1,3}$')
if [ $is_ipv4 -ne 1 ] && [ "$PLAYBACK_DISTRIBUTOR_HOST" != "host.docker.internal" ]; then
	PLAYBACK_DISTRIBUTOR_HOST=$(avahi-resolve -4 -n $PLAYBACK_DISTRIBUTOR_HOST | awk '{print $2}')
fi

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
