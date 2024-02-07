# Dockerfile to build Sound Detector
#
# NOTE: If you were to run the docker build manually, do it from the root of the
# repository pointing to this Dockerfile with the `-f` flag:
#
#   docker build -f sound-detector/Dockerfile -t manually-created-sound-detector-image .
#
# NOTE: Some development dependencies have been brought in after seeing what the 
# devcontainer's python features bring you. The Python features only work when using
# Dev Containers without Docker Compose but we use Compose for meshing together the
# various containers.
#
#   https://containers.dev/features
#   https://github.com/devcontainers/features/blob/main/src/python/install.sh
#

FROM python:3.10.13-slim-bookworm

WORKDIR /app/sound-detector

# Set to `1` if you are not on a Raspberry Pi. Accessible during build time (build
# argument) as well as during run time (environment variable).
#
#   docker build --build-arg=DEBUG=1 ...
#
ARG DEBUG=0
ENV DEBUG=$DEBUG

# Slim won't have `gcc` which is needed by building some Python depenencies.
#
#   https://github.com/docker-library/python/issues/60#issuecomment-134322383
#
# - gcc & libc-dev: Needed to compile TensorFlow modules.
#
ARG BUILD_TIME_DEPENDENCIES="\
  gcc \
  libc-dev \
  "

ARG RUN_TIME_DEPENDENCIES="\
  avahi-utils \
  portaudio19-dev \
  libasound2-plugins \
  "

ARG DEBUG_DEPENDENCIES="\
  iputils-ping \
  pulseaudio-utils \
  alsa-utils \
  "

# The --no-install-recommends helps limit some of the install so that you can be more
# explicit about what gets installed.
#
# - pulseaudio-utils: Client-side tools to interact with PulseAudio: pactl, paplay,
#   parecord, etc...
# - libasound2-plugins: Needed for configuring ALSA to use PulseAudio. It provides
#   libasound_module_pcm_pulse.so. PyAudio does not understand PulseAudio only ALSA, so
#   within the container we need to setup the ALSA configuration to inform that ALSA
#   should delegate the input and output to the devices from PulseAudio server. In the
#   README.md there's a section dedicated to container sound.
# - portaudio19-dev: Needed by PyAudio.
#
RUN apt-get update && apt-get install -y --no-install-recommends \
  $BUILD_TIME_DEPENDENCIES \
  $RUN_TIME_DEPENDENCIES \
  $( [ $DEBUG = 1 ] && echo $DEBUG_DEPENDENCIES )

# Place the ALSA configuration on the $HOME for PyAudio's ALSA to resolve it and
# understand that the input and output devices are delegated to PulseAudio.
COPY .asoundrc /root/.asoundrc

# Install Poetry and use it to install the project dependencies.
COPY sound-detector/pyproject.toml sound-detector/poetry.lock ./
RUN pip install --upgrade setuptools wheel \
  && pip install --upgrade keyrings.alt \
  && pip install poetry==1.7.1 \
  && poetry config virtualenvs.create false

# Pass this build argument as follows:
#
#   docker build --build-arg=INSTALL_DEV_DEPS=1 --build-arg=USE_TFLITE=0 ...
#
# The build arguments will be available as an environment variable in the container too.
#
# USE_TFLITE: Will use TensorFlow Lite for inference instead of the TensorFlow Core
#   module. Therefore it will run faster. You cannot create new models with Lite, only
#   run them (inference).
#
# INSTALL_DEV_DEPS: Will install development packages for running interactive Jupyter
#   Notebooks, Neovim libraries and LSP, linters, formatters... 
#
ARG INSTALL_DEV_DEPS=0
ENV INSTALL_DEV_DEPS=$INSTALL_DEV_DEPS
ARG USE_TFLITE=1
ENV USE_TFLITE=$USE_TFLITE

# Build and install python project dependencies and just after that cleanup the dev libs
# that were needed for that build and installation process.
RUN eval poetry install --no-interaction \
  $( [ $INSTALL_DEV_DEPS = 0 ] && echo --without dev ) \
  $( [ $USE_TFLITE = 0 ] && echo --with tensorflow-dev ) \
  && apt-get purge -y $BUILD_TIME_DEPENDENCIES \
  && apt-get autoremove -y --purge

COPY sound-detector/.ignore-sounds sound-detector/sound_detector.py  sound-detector/tests ./

ENV SKIP_RECORDING=0
ENV SKIP_DETECTION_NOTIFICATION=0
ENV INFLUX_DB_HOST=host.docker.internal
ENV PLAYBACK_DISTRIBUTOR_HOST=host.docker.internal

ENTRYPOINT [ "python", "sound_detector.py" ]
