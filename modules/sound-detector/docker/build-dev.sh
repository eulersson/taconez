#!/bin/bash

# Builds a development image of the Sound Detector module.
#
# Intended for local container development mainly.

TACONEZ_ROOT=$(echo $(realpath $0) | sed 's|/modules/sound-detector.*||')

docker build \
  --build-arg="DEBUG=1" \
  --build-arg="INSTALL_DEV_DEPS=1" \
  --build-arg="USE_TFLITE=1" \
  --tag taconez/sound-detector:dev \
  --file $TACONEZ_ROOT/modules/sound-detector/Dockerfile \
  $TACONEZ_ROOT
