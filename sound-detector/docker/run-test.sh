#!/bin/bash

# Runs a test container of the Sound Detector module.
#
# To build an image for it first run ./sound-detector/docker/build-test.sh (from project root).

docker run --tty --interactive --entrypoint pytest anesowa/sound-detector:test