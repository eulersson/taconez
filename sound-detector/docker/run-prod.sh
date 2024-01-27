#!/bin/bash

# Runs a production container of the Sound Detector module.
#
# This script will be launched by the Raspberry Pi systemd service's ExecStart:
#
# - sound-detector/service/taconez-sound-detector.service
# - sound-detector/service/exec-start.sh
#
# You can also launch it from the local machine instead too for debugging purposes.

TACONEZ_ROOT=$(echo $(realpath $0) | sed 's|/sound-detector.*||')

# If launched by the systemd service these environment variables will be set.
TACONEZ_CONTAINER_NAME=${TACONEZ_CONTAINER_NAME:-taconez-sound-detector}
TACONEZ_VERSION=${TACONEZ_VERSION:-prod}
INFLUX_DB_TOKEN=${INFLUX_DB_TOKEN:-no_token}

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

# Useful for seeing the actual command that's run on the service logs.
set -x

docker run --tty \
  --env INFLUX_DB_HOST=host.docker.internal \
  --env INFLUX_DB_TOKEN=$INFLUX_DB_TOKEN \
  --env PLAYBACK_DISTRIBUTOR_HOST=host.docker.internal \
  --env PULSE_SERVER=host.docker.internal \
  --volume $PULSEAUDIO_COOKIE:/root/.config/pulse/cookie \
  --volume $recordings_source_dir:/app/recordings \
  --name $TACONEZ_CONTAINER_NAME \
  $extra_flags \
  taconez/sound-detector:$TACONEZ_VERSION

set +x
