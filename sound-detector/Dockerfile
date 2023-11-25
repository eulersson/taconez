FROM python:3.10.13-slim-bookworm

WORKDIR /anesowa/sound-detector/

# Slim won't have `gcc` which is needed by building some Python depenencies.
#
#   https://github.com/docker-library/python/issues/60#issuecomment-134322383
#
# The --no-install-recommends helps limit some of the install so that you can be more
# explicit about what gets installed.
RUN apt-get update && apt-get install -y --no-install-recommends \
  gcc libc-dev portaudio19-dev

# Needed for configuring ALSA to use PulseAudio. It proviedes libasound_module_pcm_pulse.so.
# This is because when running the container from a non-Linux machine you cannot bind
# the audio or microphone devices, so you rely on passing the audio to the PulseAudio
# server running on the host. PyAudio does not understand PulseAudio, so within the
# container we need to setup the ALSA configuration to inform that ALSA should use the
# devices from PulseAudio server.
#
# In the README.md there's a "Sound" section dedicated to container sound.
#
RUN apt-get install -y libasound2-plugins

# Needed only for debugging so we can run paplay from the host.
RUN apt-get install -y pulseaudio-utils

# TODO: Cleanup gcc and libc-dev and other build-time dependencies after installing poetry depenencies?

COPY pyproject.toml poetry.lock README.md ./

RUN pip install --upgrade pip setuptools wheel \
  && pip install --upgrade keyrings.alt \
  && pip install poetry==1.7.1 \
  && poetry config virtualenvs.create false


# Pass this build argument as follows:
#
#   docker build --build-arg=INSTALL_TENSORFLOW_DEV_DEPS=1 ...
#
ARG INSTALL_TENSORFLOW_DEV_DEPS=0

# The build argument will be available as an environment variable in the container too.
ENV INSTALL_TENSORFLOW_DEV_DEPS=$INSTALL_TENSORFLOW_DEV_DEPS

RUN eval poetry install --no-interaction \
  $( [ $INSTALL_TENSORFLOW_DEV_DEPS = "1" ] && echo --with tensorflow-dev )

ENV USE_TFLITE=0
 
COPY . .
