#!/bin/bash

# Builds a development image of the Sound Detector module.
#
# Intended for local container development mainly.

if [ "$(uname)" == "Darwin" ]; then
    ANESOWA_PROJECT_ROOT=${ANESOWA_PROJECT_ROOT:-$HOME/Devel/anesowa}
    docker build \
      --build-arg="DEBUG=1" \
      --build-arg="INSTALL_DEV_DEPS=1" \
      --build-arg="USE_TFLITE=0" \
      --tag anesowa/sound-detector:dev $ANESOWA_PROJECT_ROOT/sound-detector
elif [ "$(uname)" == "Linux" ]; then
    ANESOWA_PROJECT_ROOT=${ANESOWA_PROJECT_ROOT:-/app/anesowa}
    docker build \
      --build-arg="DEBUG=1" \
      --build-arg="INSTALL_DEV_DEPS=1" \
      --build-arg="USE_TFLITE=1" \
      --tag anesowa/sound-detector:dev $ANESOWA_PROJECT_ROOT/sound-detector
fi
