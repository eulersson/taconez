#!/bin/bash

# Runs a development container of the Sound Player module.
#
# Intended for local container development mainly.

ENTRYPOINT="$1"

ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/playback-distributor.*||')

if [ "$(uname)" == "Linux" ]; then
  extra_flags=--add-host=host.docker.internal:host-gateway
else
  extra_flags=""
fi

entrypoint=""
if [ "$ENTRYPOINT" ]; then
  entrypoint="--entrypoint $ENTRYPOINT"
fi

# Useful for seeing the actual command that's run on the service logs.
set -x

docker run \
  --rm \
  --tty \
  --interactive \
  --publish 5555:5555 \
  --publish 5556:5556 \
  --volume $ANESOWA_ROOT/playback-distributor:/anesowa/playback-distributor \
  $extra_flags \
  $entrypoint \
  anesowa/playback-distributor:dev

set +x
