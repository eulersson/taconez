#!/bin/bash

# Runs a development container of the Sound Detector module.
#
# Intended for local container development mainly.

# Useful for seeing the actual command that's run on the service logs.
set -x

ENTRYPOINT="$1"

TACONEZ_ROOT=$(echo $(realpath $0) | sed 's|/sound-detector.*||')
PULSEAUDIO_COOKIE=${PULSEAUDIO_COOKIE:-$HOME/.config/pulse/cookie}

extra_flags=""
if [ "$(uname)" == "Linux" ]; then
  extra_flags="--add-host=host.docker.internal:host-gateway"
fi

entrypoint=""
if [ "$ENTRYPOINT" ]; then
  entrypoint="--entrypoint $ENTRYPOINT"
fi

MACHINE_ID=${MACHINE_ID:-rpi}
MACHINE_ROLE=${MACHINE_ROLE:-slave}

# Check if PLAYBACK_DISTRIBUTOR_HOST is not an IPv4 address and not host.docker.internal
PLAYBACK_DISTRIBUTOR_HOST=${PLAYBACK_DISTRIBUTOR_HOST:-host.docker.internal}
is_ipv4=$(echo "$PLAYBACK_DISTRIBUTOR_HOST" | grep -cEo '^([0-9]{1,3}\.){3}[0-9]{1,3}$')
if [ $is_ipv4 -ne 1 ] && [ "$PLAYBACK_DISTRIBUTOR_HOST" != "host.docker.internal" ]; then
	PLAYBACK_DISTRIBUTOR_HOST=$(avahi-resolve -4 -n $PLAYBACK_DISTRIBUTOR_HOST | awk '{print $2}')
fi

docker run --rm --tty --interactive \
  --env INFLUX_DB_HOST=host.docker.internal \
  --env INFLUX_DB_TOKEN=no_token \
  --env PLAYBACK_DISTRIBUTOR_HOST=$PLAYBACK_DISTRIBUTOR_HOST \
  --env PULSE_SERVER=host.docker.internal \
  --env SKIP_DETECTION_NOTIFICATION=False \
  --env SKIP_RECORDING=False \
  --env MACHINE_ID=$MACHINE_ID \
  --env MACHINE_ROLE=$MACHINE_ROLE \
  --volume $PULSEAUDIO_COOKIE:/root/.config/pulse/cookie \
  --volume $TACONEZ_ROOT/sound-detector:/app/sound-detector \
  --volume $TACONEZ_ROOT/prerolls:/app/prerolls \
  --volume $TACONEZ_ROOT/recordings:/app/recordings \
  $extra_flags \
  $entrypoint \
  taconez/sound-detector:dev

set +x
