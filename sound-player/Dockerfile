# Dockerfile to build Sound Player
#
# NOTE: It's encouraged to use the scripts that wrap the `docker build` and `docker run`:
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
ARG BUILD_DEPENDENCIES="\
  cmake \
  gcc \
  g++ \
  make \
  ruby \
  "
# TODO: gem pristine ruby-filemagic --version 0.7.2???

# Extra dependencies only installed when the DEBUG build argument is passed.
ARG DEBUG_DEPENDENCIES="\
  iputils-ping \
  pulseaudio-utils \
  alsa-utils \
  "

# Choose between installing dependencies or having them built from source with CMake.
ARG DEPENDENCIES_COMPILE_FROM_SOURCE=1
ARG COMPILABLE_DEPENDENCIES="\
  cmocka-dev \
  cjson-dev \
  zeromq-dev \
  "

FROM alpine:3.19.0 as base

# Use args from the global scope.
#
#  - Share ARG in multi-stage Dockerfile
#    https://therdnotes.com/sharing-arg-in-multi-stage-dockerfile
#
ARG DEBUG
ARG BUILD_DEPENDENCIES
ARG DEPENDENCIES_COMPILE_FROM_SOURCE
ENV DEPENDENCIES_COMPILE_FROM_SOURCE=$DEPENDENCIES_COMPILE_FROM_SOURCE
ARG COMPILABLE_DEPENDENCIES

WORKDIR /anesowa/sound-player

# Install dependencies.
RUN apk --no-cache --update add \
  pulseaudio-dev \
  $BUILD_DEPENDENCIES \
  $( [ $DEBUG = 1 ] && echo $DEBUG_DEPENDENCIES ) \
  $( [ $DEPENDENCIES_COMPILE_FROM_SOURCE = 0 ] && echo $COMPILABLE_DEPENDENCIES )

# Build the module.
COPY lib /anesowa/lib
COPY sound-player/CMakeLists.txt ./
COPY sound-player/src ./src

# docker run ... --target dev
FROM base as development

RUN cmake -S . -B build -DBUILD_TYPE=development --fresh
RUN cmake --build build --verbose

ENTRYPOINT [ "./build/sound-player" ]

# docker run ... --target test
FROM base as test

# Use args from the global scope.
#
#  - Share ARG in multi-stage Dockerfile
#    https://therdnotes.com/sharing-arg-in-multi-stage-dockerfile
#
ARG DEBUG
ENV DEBUG=$DEBUG
ARG DEPENDENCIES_COMPILE_FROM_SOURCE
ENV DEPENDENCIES_COMPILE_FROM_SOURCE=$DEPENDENCIES_COMPILE_FROM_SOURCE

COPY sound-player/tests ./tests

RUN cmake -S . -B build -DBUILD_TYPE=test
RUN cmake --build build --verbose

# TODO: Collect results together so one test suite does not stop subsequent ones.
ENTRYPOINT echo "RUNNING PROJECT TESTS" \
 && ctest --output-on-failure --test-dir build  \
 && echo "RUNNING DEPENDENCY TESTS: cJSON" \
 && ctest --output-on-failure --test-dir build/anesowa_commons/cjson-prefix/src/cjson-build \
 && echo "RUNNING DEPENDENCY TESTS: cmocka" \
 && ctest --output-on-failure --test-dir build/anesowa_commons/cmocka-prefix/src/cmocka-build \
 && echo "RUNNING DEPENDENCY TESTS: ZeroMQ" \
 && ctest --output-on-failure --test-dir build/anesowa_commons/zmq-prefix/src/zmq-build

# docker run ... --target prod
FROM base as production

RUN cmake -S . -B build -DBUILD_TYPE=production
RUN cmake --build build --verbose \
  && mv ./build/sound-player . \
  && rm -rf build

# Cleanup build-time dependencies.
#
# NOTE: In order to delete packages we cannot pass it like `apk del make=4.4.1-r1` but as
#   `apk del make` instead. The regex uses =[^ =]* to match an equals sign followed by
#   any characters that are not a space or equals sign. It replaces this matched pattern
#   with an empty string, effectively extracting only the package names. Thanks ChatGPT!
#
RUN \
  if [ $DEBUG == 0 ]; then \
  echo $BUILD_DEPENDENCIES | sed -e 's/=[^ =]*//g' | xargs apk del; \
  fi

ENTRYPOINT [ "./sound-player" ]
