#!/bin/bash

ANESOWA_CONTAINER_NAME=${ANESOWA_CONTAINER_NAME:-anesowa-sound-player}

set -x;
docker stop $ANESOWA_CONTAINER_NAME
set +x;
