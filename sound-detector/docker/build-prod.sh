#!/bin/bash

# Builds a development image of the Sound Detector module.
#
# Intended for local container development mainly.

ANESOWA_ROOT=$(echo $(realpath $0) | sed 's|/sound-detector.*||')

docker build \
  --build-arg="DEBUG=0" \
  --build-arg="INSTALL_DEV_DEPS=0" \
  --build-arg="USE_TFLITE=1" \
  --tag anesowa/sound-detector:prod \
  --file $ANESOWA_ROOT/sound-detector/Dockerfile \
  $ANESOWA_ROOT
