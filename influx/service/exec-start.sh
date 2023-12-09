#!/bin/bash

# Runs an InfluxDB service so the rest of moduels (distributor, journal) can connect to
# it as clients to write and read data.
#
# Reference:
#
# - Section: Custom Initialization Scripts (https://hub.docker.com/_/influxdb)
#

docker run --detach --publish 8086:8086 \
  --volume $PWD/data:/var/lib/influxdb2 \
  --volume $PWD/config:/etc/influxdb2 \
  --env DOCKER_INFLUXDB_INIT_MODE=setup \
  --env DOCKER_INFLUXDB_INIT_USERNAME=anesowa \
  --env DOCKER_INFLUXDB_INIT_PASSWORD=ufftQDZNDESRALXi5NbS \
  --env DOCKER_INFLUXDB_INIT_ORG=anesowa \
  --env DOCKER_INFLUXDB_INIT_BUCKET=anesowa \
  --name influx_db_server \
  influxdb:2.7.4-alpine
