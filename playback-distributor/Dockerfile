# Dockerfile to build Sound Detector
#
# NOTE: If you were to run the docker build manually, do it from the root of the
# repository pointing to this Dockerfile with the `-f` flag:
#
#   ./playback-distributor/docker/build-dev.sh
#   ./playback-distributor/docker/run-dev.sh
#
# Sources:
#
# - Docker Multi-Stage Builds
#   https://docs.docker.com/language/nodejs/run-tests/
#


FROM alpine:3.18.4 as base

WORKDIR /anesowa/playback-distributor

EXPOSE 5555
EXPOSE 5556

# Separate the dependencies that are only used to build the module and the ones that
# need to be present when running the module binaries. That way we can cleanup after
# build and have a thinner container.
#
# NOTE: g++ is needed for CMake to run the compiler tests to identify the system.
#
# TODO: See if we can skip installing g++ and have CMake work. Then we would need to
#   install libc-dev
#

ARG DEBUG=0
ENV DEBUG=$DEBUG

# Dependencies needed only at build time and that can be uninstalled afterwards.
ARG BUILD_DEPENDENCIES="\
  gcc=12.2.1_git20220924-r10 \  
  g++=12.2.1_git20220924-r10 \
  make=4.4.1-r1 \
  cmake=3.26.5-r0 \
  "

ARG DEPENDENCIES="\
  zeromq-dev=4.3.4-r4 \
  cjson-dev=1.7.15-r4 \
  "

ARG DEBUG_DEPENDENCIES="\
  iputils-ping=20221126-r2 \
  pulseaudio-utils=16.1-r10 \
  alsa-utils=1.2.9-r0 \
  "

# Install dependencies.
RUN apk --no-cache --update add \
  $BUILD_DEPENDENCIES \
  $DEPENDENCIES \
  $( [ $DEBUG = 1 ] && echo $DEBUG_DEPENDENCIES )

# Build the module.
COPY lib /anesowa/lib
COPY playback-distributor/CMakeLists.txt playback-distributor/build-cmake-project.sh ./
COPY playback-distributor/src ./src

# docker run ... --target dev
FROM base as development

RUN ./build-cmake-project.sh -DTARGET_GROUP=development

ENTRYPOINT [ "build/playback-distributor" ]

# docker run ... --target test
FROM base as test

COPY playback-distributor/test ./test

# RUN ./build-cmake-project.sh -DTARGET_GROUP=test

ENTRYPOINT [ "ctest", "--test-dir", "build", "--verbose" ]

# docker run ... --target prod
FROM base as production

RUN ./build-cmake-project.sh -DTARGET_GROUP=production

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

ENTRYPOINT [ "build/playback-distributor" ]
