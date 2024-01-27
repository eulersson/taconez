#!/bin/bash

TACONEZ_CONTAINER_NAME=${TACONEZ_CONTAINER_NAME:-taconez-sound-detector}

set -x
docker stop $TACONEZ_CONTAINER_NAME
set +x
