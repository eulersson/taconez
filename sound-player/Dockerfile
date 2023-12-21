# Dockerfile to build Sound Player
#
# NOTE: If you were to run the docker build manually, do it from the root of the
# repository pointing to this Dockerfile with the `-f` flag:
#
#   ./playback-distributor/docker/build-dev.sh
#   ./playback-distributor/docker/run-dev.sh
#

FROM alpine:3.18.4

WORKDIR /anesowa/sound-player

# Separate the dependencies that are only used to build the module and the ones that
# need to be present when running the module binaries. That way we can cleanup after
# build and have a thinner container.
#
# NOTE: g++ is needed for CMake to run the compiler tests to identify the system.
#
# TODO: See if we can skip installing g++ and have CMake work. Then we would need to
#   install libc-dev
#

# Dependencies needed only at build time and that can be uninstalled afterwards.
ARG BUILD_DEPENDENCIES="\
  gcc=12.2.1_git20220924-r10 \  
  g++=12.2.1_git20220924-r10 \
  make=4.4.1-r1 \
  cmake=3.26.5-r0 \
  "

ARG DEPENDENCIES="\
  zeromq-dev=4.3.4-r4 \
  pulseaudio-dev=16.1-r10 \
  "

ARG DEBUG_DEPENDENCIES="\
  iputils-ping=20221126-r2 \
  pulseaudio-utils=16.1-r10 \
  alsa-utils=1.2.9-r0 \
  "

# Install dependencies.
RUN apk --no-cache --update add \
  $BUILD_TIME_DEPENDENCIES \
  $RUN_TIME_DEPENDENCIES \
  $( [ $DEBUG = 1 ] && echo $DEBUG_DEPENDENCIES )

# Build the module.
COPY lib /anesowa/lib
COPY sound-player/CMakeLists.txt sound-player/build-cmake-project.sh ./
COPY sound-player/src ./src
RUN ./build-cmake-project.sh 

# Cleanup build-time dependencies.
#
# NOTE: In order to delete packages we cannot pass it like `apk del make=4.4.1-r1` but as
#   `apk del make` instead. The regex uses =[^ =]* to match an equals sign followed by
#   any characters that are not a space or equals sign. It replaces this matched pattern
#   with an empty string, effectively extracting only the package names. Thanks ChatGPT!
#
RUN \
  if [ $DEBUG == 0 ]; then \
  echo $BUILD_TIME_DEPENDENCIES | sed -e 's/=[^ =]*//g' | xargs apk del; \
  fi

ENTRYPOINT [ "build/sound-player" ]
