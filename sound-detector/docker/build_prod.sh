#!/bin/bash

# Builds a production image of the Sound Detector module.
#
# This script will be launched by the Raspberry Pi systemd service's ExecStartPre:
#
# - sound-detector/service/anesowa-sound-detector.service
# - sound-detector/service/exec-start-pre.sh
#
# You can also launch it from the local machine instead too for debugging purposes.

# If launched by the systemd service these variable will be set.
ANESOWA_VERSION=${ANESOWA_VERSION:-prod}

if [ "$(uname)" == "Darwin" ]; then
    ANESOWA_PROJECT_ROOT=${ANESOWA_PROJECT_ROOT:-$HOME/Devel/anesowa}
    docker build --tag anesowa/sound-detector:$ANESOWA_VERSION $ANESOWA_PROJECT_ROOT/sound-detector
elif [ "$(uname)" == "Linux" ]; then
    ANESOWA_PROJECT_ROOT=${ANESOWA_PROJECT_ROOT:-$HOME}

    # Useful for seeing the actual command that's run on the service logs.
    set -x;
    docker build --tag anesowa/sound-detector:$ANESOWA_VERSION $ANESOWA_PROJECT_ROOT/sound-detector
    set +x;
fi
