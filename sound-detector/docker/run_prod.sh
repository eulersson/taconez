#!/bin/bash

if [ "$(uname)" == "Darwin" ]; then
    ANESOWA_PROJECT_ROOT=$HOME/Devel/anesowa
    docker run --rm --tty \
      --env PULSE_SERVER=host.docker.internal \
      --volume $HOME/.config/pulse/cookie:/root/.config/pulse/cookie \
      --volume $ANESOWA_PROJECT_ROOT/recordings:/recordings \
      --name anesowa-sound-detector-prod \
      anesowa/sound-detector:prod
elif [ "$(uname)" == "Linux" ]; then
    # On the Raspberry Pi the user's home folder (/home/anesowa) is the project root.
    ANESOWA_PROJECT_ROOT=$HOME
    docker run --rm --tty \
      --add-host=host.docker.internal:host-gateway \
      --env PULSE_SERVER=host.docker.internal \
      --volume $HOME/.config/pulse/cookie:/root/.config/pulse/cookie \
      --volume /mnt/nfs/anesowa:/recordings \
      --name anesowa-sound-detector-prod \
      anesowa/sound-detector:prod
fi
