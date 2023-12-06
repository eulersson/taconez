#!/bin/bash

if [ "$(uname)" == "Darwin" ]; then
    ANESOWA_PROJECT_ROOT=$HOME/Devel/anesowa
    docker build --tag anesowa/sound-detector:prod $ANESOWA_PROJECT_ROOT/sound-detector
elif [ "$(uname)" == "Linux" ]; then
    # On the Raspberry Pi the user's home folder (/home/anesowa) is the project root.
    ANESOWA_PROJECT_ROOT=$HOME
    docker build --tag anesowa/sound-detector:prod $ANESOWA_PROJECT_ROOT/sound-detector
fi
