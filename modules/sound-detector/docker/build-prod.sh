#!/bin/bash

# Builds a development image of the Sound Detector module.
#
# Intended for local container development mainly.

TACONEZ_ROOT=$(echo $(realpath $0) | sed 's|/modules/sound-detector.*||')
TACONEZ_VERSION=${TACONEZ_VERSION:-prod}

docker build \
  --build-arg="DEBUG=0" \
  --build-arg="INSTALL_DEV_DEPS=0" \
  --build-arg="USE_TFLITE=1" \
  --tag taconez/sound-detector:$TACONEZ_VERSION \
  --file $TACONEZ_ROOT/modules/sound-detector/Dockerfile \
  $TACONEZ_ROOT
