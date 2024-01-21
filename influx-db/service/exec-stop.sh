#!/bin/bash

INFLUX_DB_CONTAINER_NAME=${INFLUX_DB_CONTAINER_NAME:-influx-db-server}

set -x
docker stop $INFLUX_DB_CONTAINER_NAME
set +x
