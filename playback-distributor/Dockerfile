# Dockerfile to build Sound Detector
#
# NOTE: If you were to run the docker build manually, do it from the root of the
# repository pointing to this Dockerfile with the `-f` flag:
#
#   docker build -f playback-distributor/Dockerfile -t manually-created-playback-distributor-image .
#

FROM alpine:3.18.4

WORKDIR /anesowa/playback-distributor

# Separate the dependencies that are only used to build the module and the ones that
# need to be present when running the module binaries. That way we can cleanup after
# build and have a thinner container.
#
# NOTE: g++ is needed for CMake to run the compiler tests to identify the system.
#
# TODO: See if we can skip installing g++ and have CMake work. Then we would need to
#   install libc-dev
#
ARG BUILD_TIME_DEPENDENCIES="\
  gcc=12.2.1_git20220924-r10 \  
  g++=12.2.1_git20220924-r10 \
  make=4.4.1-r1 \
  cmake=3.26.5-r0 \
  "

ARG RUN_TIME_DEPENDENCIES="\
  zeromq-dev=4.3.4-r4 \
  "

# Install build dependencies.
RUN apk --no-cache --update add $BUILD_TIME_DEPENDENCIES $RUN_TIME_DEPENDENCIES 

# Build the module.
COPY lib /anesowa/lib
COPY playback-distributor/CMakeLists.txt playback-distributor/*.c ./

RUN cmake -S . -B build --fresh && cmake --build build --verbose

# Cleanup build-time dependencies.
#
# NOTE: In order to delete packages we cannot pass it like `apk del make=4.4.1-r1` but as
#   `apk del make` instead. The regex uses =[^ =]* to match an equals sign followed by
#   any characters that are not a space or equals sign. It replaces this matched pattern
#   with an empty string, effectively extracting only the package names. Thanks ChatGPT!
#
RUN echo $BUILD_TIME_DEPENDENCIES | sed -e 's/=[^ =]*//g' | xargs apk del

ENTRYPOINT [ "build/playback-distributor" ]

