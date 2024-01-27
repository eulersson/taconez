#!/bin/bash

TACONEZ_CONTAINER_NAME=${TACONEZ_CONTAINER_NAME:-taconez-playback-distributor}

set -x
docker stop $TACONEZ_CONTAINER_NAME
set +x
