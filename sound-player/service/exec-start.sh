#!/bin/bash

# If launched by the systemd service these enviornment variable will be set.
ANESOWA_CONTAINER_NAME=${ANESOWA_CONTAINER_NAME:-anesowa-sound-player}

if [[ "$(docker ps -aq --filter name=$ANESOWA_CONTAINER_NAME)" = "" ]]; then
  echo Container $ANESOWA_CONTAINER_NAME does not exist, creating a new one.
  {{ project_root_remote }}/sound-player/docker/run-prod.sh
else
  echo Container $ANESOWA_CONTAINER_NAME already exists, starting instead of creating a new one.
  docker start --attach $ANESOWA_CONTAINER_NAME
fi
