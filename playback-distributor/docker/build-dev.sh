#!/bin/bash

# Builds a development image of the Sound Detector module.
#
# Intended for local container development mainly.

if [ "$(uname)" == "Darwin" ]; then
    ANESOWA_PROJECT_ROOT=${ANESOWA_PROJECT_ROOT:-$HOME/Devel/anesowa}
    docker build \
      --tag anesowa/playback-distributor:dev $ANESOWA_PROJECT_ROOT/playback-distributor
elif [ "$(uname)" == "Linux" ]; then
    ANESOWA_PROJECT_ROOT=${ANESOWA_PROJECT_ROOT:-$HOME}
    docker build \
      --tag anesowa/playback-distributor:dev $ANESOWA_PROJECT_ROOT/playback-distributor
fi
