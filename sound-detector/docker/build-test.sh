#!/bin/bash

# Builds a test image of the Sound Detector module.

TACONEZ_ROOT=$(echo $(realpath $0) | sed 's|/sound-detector.*||')

docker build \
  --build-arg="DEBUG=0" \
  --build-arg="INSTALL_DEV_DEPS=1" \
  --build-arg="USE_TFLITE=1" \
  --tag taconez/sound-detector:test \
  --file $TACONEZ_ROOT/sound-detector/Dockerfile \
  $TACONEZ_ROOT
