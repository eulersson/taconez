#!/bin/sh

# NOTE: Ideally should be run from project root so that docker can copy over files
# shared across the various containers and images (e.g. taconez_root/lib/c/common). If
# not run from root we protect the script by finding the root as follows.
TACONEZ_ROOT=$(echo $(realpath $0) | sed 's|/scripts/retrain-network.*||')

set -x # Print commands as they run.

docker build \
  --build-arg RETRAIN_NETWORK=1 \
  --build-arg DEBUG=1 \
  --build-arg INSTALL_DEV_DEPS=1 \
  --build-arg USE_TFLITE=0 \
  -t taconez/retrain-network \
  -f $TACONEZ_ROOT/modules/sound-detector/Dockerfile \
  $TACONEZ_ROOT

docker run \
  -it --rm \
  -v $TACONEZ_ROOT/dataset:/app/dataset \
  -v $TACONEZ_ROOT/modules/sound-detector/sound_detector/models/custom:/app/sound-detector/sound_detector/models/custom \
  -v $TACONEZ_ROOT/modules/sound-detector/sound_detector/models/downloads:/app/sound-detector/sound_detector/models/downloads \
  taconez/retrain-network \
  retrain

set +x