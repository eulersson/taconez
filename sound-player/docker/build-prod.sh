#!/bin/bash

# Builds a development image of the Sound Player module.
#
# Intended for local container development mainly.

ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/sound-player.*||')

docker build \
  --build-arg DEBUG=0 \
  --tag anesowa/sound-player:prod \
  --file $ANESOWA_ROOT/sound-player/Dockerfile \
  $ANESOWA_ROOT

