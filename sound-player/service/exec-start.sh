#!/bin/bash

# If launched by the systemd service these enviornment variable will be set.
TACONEZ_CONTAINER_NAME=${TACONEZ_CONTAINER_NAME:-taconez-sound-player}

if [[ "$(docker ps -aq --filter name=$TACONEZ_CONTAINER_NAME)" = "" ]]; then
  echo Container $TACONEZ_CONTAINER_NAME does not exist, creating a new one.
  {{ project_root_remote }}/sound-player/docker/run-prod.sh
else
  echo Container $TACONEZ_CONTAINER_NAME already exists, starting instead of creating a new one.
  docker start --attach $TACONEZ_CONTAINER_NAME
fi
