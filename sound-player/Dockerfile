# Dockerfile to build Sound Player
#
# NOTE: (VS Code users) Dev Containers are provided:
#
#   https://github.com/eulersson/taconez/blob/main/docs/5-configuring-your-ide.md#visual-studio-code
#
# NOTE: (non-VS Code users) Scripts that wrap the `docker build` and `docker run`:
#
#   ./sound-player/docker/build-dev.sh
#   ./sound-player/docker/run-dev.sh
#
# This file is a multi-stage build so we can target either "development", "production"
# or test with the `docker build` `--target` argument.
#
# Sources:
#
# - Docker Multi-Stage Builds
#   https://docs.docker.com/language/nodejs/run-tests/
#

# Would include more verbosity and install extra utilities for debugging.
ARG DEBUG=0

# Separate the dependencies that are only used to build the module and the ones that
# need to be present when running the module binaries. That way we can clean them up
# after build and have a thinner container.
#
# NOTE: g++ is needed for CMake to run the compiler tests to identify the system.
#
ARG BUILD_TIME_DEPENDENCIES="\
  cmake \
  g++ \
  gcc \
  make \
  ruby \
  "

ARG RUN_TIME_DEPENDENCIES="\
  avahi-utils \
  "

# Extra dependencies only installed when the DEBUG build argument is passed.
ARG DEBUG_DEPENDENCIES="\
  gdb \
  iputils-ping \
  pulseaudio-utils \
  alsa-utils \
  "

# Choose between installing dependencies or having them built from source with CMake.
ARG DEPENDENCIES_COMPILE_FROM_SOURCE=1
ARG COMPILABLE_DEPENDENCIES="\
  libcjson-dev \
  libzmq3-dev \
  "

# For Visual Studio Dev Containers. That way we don't have to wait to compile since the
# build folder will disappear once we map the volume on top. VS Code mounts the entire
# repository folder as a volume on top of the container, it's not as selective as the
# docker scripts in `sound-player/docker/run-{dev|pro}`.
ARG SKIP_BUILD=0

# FROM alpine:3.19.0 as base
FROM debian:12.4-slim as base

# Use args from the global scope.
#
#  - Share ARG in multi-stage Dockerfile
#    https://therdnotes.com/sharing-arg-in-multi-stage-dockerfile
#
ARG DEBUG
ARG BUILD_TIME_DEPENDENCIES
ARG RUN_TIME_DEPENDENCIES
ARG DEBUG_DEPENDENCIES
ARG DEPENDENCIES_COMPILE_FROM_SOURCE
ARG COMPILABLE_DEPENDENCIES

ENV DEPENDENCIES_COMPILE_FROM_SOURCE=$DEPENDENCIES_COMPILE_FROM_SOURCE

WORKDIR /app/sound-player

# Install dependencies.
RUN apt-get update && apt-get install -y \
  git \
  libpulse-dev \
  $BUILD_TIME_DEPENDENCIES \
  $RUN_TIME_DEPENDENCIES \
  $( [ $DEBUG = 1 ] && echo $DEBUG_DEPENDENCIES ) \
  $( [ $DEPENDENCIES_COMPILE_FROM_SOURCE = 0 ] && echo $COMPILABLE_DEPENDENCIES )

# Build the module.
COPY lib /app/lib
COPY sound-player/CMakeLists.txt ./
COPY sound-player/src ./src

# --- docker run ... --target development ----------------------------------------------
FROM base as development

# Use args from the global scope.
#
#  - Share ARG in multi-stage Dockerfile
#    https://therdnotes.com/sharing-arg-in-multi-stage-dockerfile
#
ARG SKIP_BUILD

RUN \
  if [ $SKIP_BUILD = 0 ]; then \
    cmake -S . -B build --fresh \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_BUILD_TYPE=Debug; \
  fi

# NOTE: The `--config Debug` is ignored because we use Unix Makefiles, so if you want to
# change from Debug to Release you need to delete the build folder and configure again.
# The flag would be honoured if we used Ninja multi-configuration generator.
RUN \
  if [ $SKIP_BUILD = 0 ]; then\
    cmake --build build --config Debug --verbose; \
  fi

ENTRYPOINT [ "/app/sound-player/build/sound-player" ]

# --- docker run ... --target production -----------------------------------------------
FROM base as production

# Use args from the global scope.
#
#  - Share ARG in multi-stage Dockerfile
#    https://therdnotes.com/sharing-arg-in-multi-stage-dockerfile
#
ARG SKIP_BUILD

RUN \
  if [ $SKIP_BUILD = 0 ]; then \
    cmake -S . -B build \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_BUILD_TYPE=Release; \
  fi

# Build the project, install it to the system and remove the source code to keep the
# container thin.
#
# NOTE: The `--config Release` is ignored because we use Unix Makefiles, so if you want to
# change from Debug to Release you need to delete the build folder and configure again.
# The flag would be honoured if we used Ninja multi-configuration generator.
#
RUN \
  if [ $SKIP_BUILD = 0 ]; then \
    cmake --build build --config Release --verbose \
    && cmake --install build \
    && rm -rf /app/sound-player; \
  fi

# Cleanup build-time dependencies.
#
# NOTE: In order to delete packages we cannot pass it like `apt-get purge make=4.4.1-r1`
#   but as `apt-get purge make` instead. The regex uses =[^ =]* to match an equals sign
#   followed by any characters that are not a space or equals sign. It replaces this
#   matched pattern with an empty string, effectively extracting only the package names.
#
RUN \
  if [ $DEBUG == 0 ]; then \
    echo $BUILD_TIME_DEPENDENCIES | sed -e 's/=[^ =]*//g' | xargs apt-get purge -y; \
    apt-get purge -y git \
    apt-get autoremove -y --purge; \
  fi

ENTRYPOINT [ "/usr/bin/sound-player" ]

# --- docker run ... --target test -----------------------------------------------------
FROM base as test

# Use args from the global scope.
#
#  - Share ARG in multi-stage Dockerfile
#    https://therdnotes.com/sharing-arg-in-multi-stage-dockerfile
#
ARG DEBUG
ARG DEPENDENCIES_COMPILE_FROM_SOURCE
ARG SKIP_BUILD

ENV DEBUG=$DEBUG
ENV DEPENDENCIES_COMPILE_FROM_SOURCE=$DEPENDENCIES_COMPILE_FROM_SOURCE

COPY sound-player/tests ./tests

RUN \
  if [ $SKIP_BUILD = 0 ]; then \
      cmake -S . -B build \
        -DCMAKE_INSTALL_PREFIX:PATH=/usr \
        -DCMAKE_BUILD_TYPE:STRING=Debug \
        -DTACONEZ_BUILD_TESTS:BOOL=TRUE \
        -DTACONEZ_BUILD_COMMON_TESTS:BOOL=TRUE; \
  fi

# NOTE: The `--config Debug` is ignored because we use Unix Makefiles, so if you want to
# change from Debug to Release you need to delete the build folder and configure again.
# The flag would be honoured if we used Ninja multi-configuration generator.
RUN \
  if [ $SKIP_BUILD = 0 ]; then \
    cmake --build build --config Debug --verbose; \
  fi

ENV RUN_DEPENDENCY_TESTS=0
ENV RUN_PROJECT_TESTS=1

ENTRYPOINT \
  if [ $RUN_DEPENDENCY_TESTS = 1 ]; then \
    echo "::: RUNNING DEPENDENCY TESTS: cJSON :::" \
      && ctest  --output-on-failure --test-dir build/taconez_commons/cjson-prefix/src/cjson-build; \
    echo "::: RUNNING DEPENDENCY TESTS: ZeroMQ :::" \
      && ctest  --output-on-failure --test-dir build/taconez_commons/zmq-prefix/src/zmq-build; \
  fi && \
  if [ $RUN_PROJECT_TESTS = 1 ]; then \
    echo "::: RUNNING PROJECT TESTS :::" \
      && ctest  --output-on-failure --test-dir build --output-on-failure; \
  fi
