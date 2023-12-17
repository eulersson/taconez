#!/bin/bash

# Builds a development image of the Sound Detector module.
#
# Intended for local container development mainly.

ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/playback-distributor.*||')

docker build \
  --tag anesowa/playback-distributor:prod \
  --file $ANESOWA_ROOT/playback-distributor/Dockerfile \
  $ANESOWA_ROOT

