#!/bin/bash

if [ "$(uname)" == "Darwin" ]; then
    ANESOWA_PROJECT_ROOT=$HOME/Devel/anesowa
    docker build \
      --build-arg="DEBUG=1" \
      --build-arg="INSTALL_DEV_DEPS=1" \
      --build-arg="USE_TFLITE=0" \
      --tag anesowa/sound-detector:prod $ANESOWA_PROJECT_ROOT/sound-detector
elif [ "$(uname)" == "Linux" ]; then
    # On the Raspberry Pi the user's home folder (/home/anesowa) is the project root.
    ANESOWA_PROJECT_ROOT=$HOME
    docker build \
      --build-arg="DEBUG=1" \
      --build-arg="INSTALL_DEV_DEPS=1" \
      --build-arg="USE_TFLITE=1" \
      --tag anesowa/sound-detector:prod $ANESOWA_PROJECT_ROOT/sound-detector
fi
