# Dockerfile to build Playback Distributor
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
# TODO: Versioning pkgconfig does not work... Ideally we want to pin down a version.
#
ARG BUILD_DEPENDENCIES="\
  gcc=12.2.1_git20220924-r10 \  
  g++=12.2.1_git20220924-r10 \
  make=4.4.1-r1 \
  cmake=3.26.5-r0 \
  pkgconfig \
  "

# Extra dependencies only installed when the DEBUG build argument is passed.
ARG DEBUG_DEPENDENCIES="\
  iputils-ping=20221126-r2 \
  pulseaudio-utils=16.1-r10 \
  alsa-utils=1.2.9-r0 \
  "

# Choose between installing dependencies or having them built from source with CMake.
ARG INSTALL_DEPENDENCIES_FROM_PACKAGE=0
ARG DEPENDENCIES="\
  cjson-dev=1.7.15-r4 \
  zeromq-dev=4.3.4-r4 \
  "

# NOTE: It's encouraged to use the scripts that wrap the `docker build` and `docker run`:
#
#   ./playback-distributor/docker/build-dev.sh
#   ./playback-distributor/docker/run-dev.sh
#
FROM alpine:3.18.4 as base

# Use args from the global scope.
#
#  - Share ARG in multi-stage Dockerfile
#    https://therdnotes.com/sharing-arg-in-multi-stage-dockerfile
#
ARG DEBUG
ARG BUILD_DEPENDENCIES
ARG INSTALL_DEPENDENCIES_FROM_PACKAGE
ENV INSTALL_DEPENDENCIES_FROM_PACKAGE=$INSTALL_DEPENDENCIES_FROM_PACKAGE
ARG DEPENDENCIES

WORKDIR /anesowa/playback-distributor

EXPOSE 5555
EXPOSE 5556

# Install dependencies.
RUN apk --no-cache --update add \
  $BUILD_DEPENDENCIES \
  $( [ ${DEBUG} = 1 ] && echo $DEBUG_DEPENDENCIES ) \
  $( [ ${INSTALL_DEPENDENCIES_FROM_PACKAGE} = 1 ] && echo $DEPENDENCIES )

# Build the module.
COPY lib /anesowa/lib
COPY playback-distributor/CMakeLists.txt  ./
COPY playback-distributor/src ./src

# docker run ... --target dev
FROM base as development

RUN cmake -S . -B build -DTARGET_GROUP=development
RUN cmake --build build --verbose

ENTRYPOINT [ "./build/playback-distributor" ]

# docker run ... --target test
FROM base as test

# Use args from the global scope.
#
#  - Share ARG in multi-stage Dockerfile
#    https://therdnotes.com/sharing-arg-in-multi-stage-dockerfile
#
ARG DEBUG
ENV DEBUG=$DEBUG
ARG INSTALL_DEPENDENCIES_FROM_PACKAGE
ENV INSTALL_DEPENDENCIES_FROM_PACKAGE=$INSTALL_DEPENDENCIES_FROM_PACKAGE

COPY playback-distributor/tests ./tests

# TODO: Test each _dep individually.
RUN cmake -S . -B build -DTARGET_GROUP=test
RUN cmake --build build --verbose

ENTRYPOINT [ "ctest", "--test-dir", "build", "--verbose" ]

# docker run ... --target prod
FROM base as production

RUN cmake -S . -B build -DTARGET_GROUP=production
RUN cmake --build build --verbose \
  && mv ./build/playback-distributor . \
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

ENTRYPOINT [ "./playback-distributor" ]
