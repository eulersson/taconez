#!/bin/bash

# Runs a production container of the Sound Detector module.
#
# This script will be launched by the Raspberry Pi systemd service's ExecStart:
#
# - sound-detector/service/anesowa-sound-detector.service
# - sound-detector/service/exec-start.sh
#
# You can also launch it from the local machine instead too for debugging purposes.

ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/sound-detector.*||')

# If launched by the systemd service these environment variables will be set.
ANESOWA_CONTAINER_NAME=${ANESOWA_CONTAINER_NAME:-anesowa-sound-detector}
ANESOWA_VERSION=${ANESOWA_VERSION:-prod}
INFLUX_DB_TOKEN=${INFLUX_DB_TOKEN:-no_token}

# If you instsall PulseAudio system-wide it then would be /var/run/pulse/.config/pulse/cookie!
# Don't worry this gets set in the service file.
PULSEAUDIO_COOKIE=${PULSEAUDIO_COOKIE:-$HOME/.config/pulse/cookie}

if [ "$(uname)" == "Linux" ]; then
  extra_flags="--add-host=host.docker.internal:host-gateway"
else
  extra_flags=""
fi

if [ -d "/mnt/nfs/anesowa" ]; then
  recordings_source_dir=/mnt/nfs/anesowa
else
  recordings_source_dir=$ANESOWA_ROOT/recordings
fi

# Useful for seeing the actual command that's run on the service logs.
set -x

docker run --tty \
  --env PULSE_SERVER=host.docker.internal \
  --env INFLUX_DB_HOST=host.docker.internal \
  --env PLAYBACK_DISTRIBUTOR_HOST=host.docker.internal \
  --env INFLUX_DB_TOKEN=$INFLUX_DB_TOKEN \
  --volume $PULSEAUDIO_COOKIE:/root/.config/pulse/cookie \
  --volume $recordings_source_dir:/app/recordings \
  --name $ANESOWA_CONTAINER_NAME \
  $extra_flags \
  anesowa/sound-detector:$ANESOWA_VERSION

set +x
