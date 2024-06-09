#!/bin/bash

# Runs a production container of the Sound Detector module.
#
# This script will be launched by the Raspberry Pi systemd service's ExecStart:
#
# - modules/sound-detector/service/taconez-sound-detector.service
# - modules/sound-detector/service/exec-start.sh
#
# You can also launch it from the local machine instead too for debugging purposes.

TACONEZ_ROOT=$(echo $(realpath $0) | sed 's|/modules/sound-detector.*||')

# If launched by the systemd service these environment variables will be set.
MACHINE_ID=${MACHINE_ID:-rpi}
MACHINE_ROLE=${MACHINE_ID:-slave}
TACONEZ_CONTAINER_NAME=${TACONEZ_CONTAINER_NAME:-taconez-sound-detector}
TACONEZ_VERSION=${TACONEZ_VERSION:-prod}
INFLUX_DB_TOKEN=${INFLUX_DB_TOKEN:-no_token}
DEBUG=${DEBUG:-0}
LOGGING_LEVEL=${LOGGING_LEVEL:-INFO}

# If you instsall PulseAudio system-wide it then would be /var/run/pulse/.config/pulse/cookie!
# Don't worry this gets set in the service file.
PULSEAUDIO_COOKIE=${PULSEAUDIO_COOKIE:-$HOME/.config/pulse/cookie}

if [ "$(uname)" == "Linux" ]; then
	extra_flags="--add-host=host.docker.internal:host-gateway"
else
	extra_flags=""
fi

if [ -d "/mnt/nfs/taconez" ]; then
	recordings_source_dir=/mnt/nfs/taconez
else
	recordings_source_dir=$TACONEZ_ROOT/recordings
fi

# Check if INFLUX_DB_HOST is not an IPv4 address and not host.docker.internal
INFLUX_DB_HOST=${INFLUX_DB_HOST:-host.docker.internal}
is_ipv4=$(echo "$INFLUX_DB_HOST" | grep -cEo '^([0-9]{1,3}\.){3}[0-9]{1,3}$')
if [ $is_ipv4 -ne 1 ] && [ "$INFLUX_DB_HOST" != "host.docker.internal" ]; then
	INFLUX_DB_HOST=$(avahi-resolve -4 -n $INFLUX_DB_HOST | awk '{print $2}')
fi

# Check if PLAYBACK_DISTRIBUTOR_HOST is not an IPv4 address and not host.docker.internal
PLAYBACK_DISTRIBUTOR_HOST=${PLAYBACK_DISTRIBUTOR_HOST:-host.docker.internal}
is_ipv4=$(echo "$PLAYBACK_DISTRIBUTOR_HOST" | grep -cEo '^([0-9]{1,3}\.){3}[0-9]{1,3}$')
if [ $is_ipv4 -ne 1 ] && [ "$PLAYBACK_DISTRIBUTOR_HOST" != "host.docker.internal" ]; then
	PLAYBACK_DISTRIBUTOR_HOST=$(avahi-resolve -4 -n $PLAYBACK_DISTRIBUTOR_HOST | awk '{print $2}')
fi

# Useful for seeing the actual command that's run on the service logs.
set -x

# dbus and avahi-daemon are needed for mDNS resolution.
#
#   https://www.reddit.com/r/AlpineLinux/comments/14kmoot/comment/jubgt0j/
#
docker run --tty \
	--env MACHINE_ID=$MACHINE_ID \
	--env MACHINE_ROLE=$MACHINE_ROLE \
	--env INFLUX_DB_HOST=$INFLUX_DB_HOST \
	--env INFLUX_DB_TOKEN=$INFLUX_DB_TOKEN \
	--env DEBUG=$DEBUG \
	--env LOGGING_LEVEL=$LOGGING_LEVEL \
	--env PLAYBACK_DISTRIBUTOR_HOST=$PLAYBACK_DISTRIBUTOR_HOST \
	--env PULSE_SERVER=host.docker.internal \
	--volume $PULSEAUDIO_COOKIE:/root/.config/pulse/cookie \
	--volume $recordings_source_dir:/app/recordings \
	--name $TACONEZ_CONTAINER_NAME \
	--volume /var/run/dbus:/var/run/dbus \
	--volume /var/run/avahi-daemon/socket:/var/run/avahi-daemon/socket \
	$extra_flags \
	taconez/sound-detector:$TACONEZ_VERSION

set +x
