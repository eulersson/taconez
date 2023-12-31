# Dockerfile to build Sound Player

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

# Dependencies needed only at build time and that can be uninstalled afterwards.
# TODO: Version pkgconfig.
ARG BUILD_DEPENDENCIES="\
  gcc=12.2.1_git20220924-r10 \  
  g++=12.2.1_git20220924-r10 \
  make=4.4.1-r1 \
  cmake=3.26.5-r0 \
  pkgconfig \
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

# When set to true we won' install the dependencies from package.
ARG INSTALL_DEPENDENCIES_FROM_PACKAGE=0
ARG DEPENDENCIES="\
  cjson-dev=1.7.15-r4 \
  zeromq-dev=4.3.4-r4 \
  "

#
# NOTE: If you were to run the docker build manually, do it from the root of the
# repository pointing to this Dockerfile with the `-f` flag:
#
#   ./sound-player/docker/build-dev.sh
#   ./sound-player/docker/run-dev.sh
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

WORKDIR /anesowa/sound-player

# Install dependencies.
RUN apk --no-cache --update add \
  pulseaudio-dev=16.1-r10 \
  $BUILD_DEPENDENCIES \
  $( [ $DEBUG = 1 ] && echo $DEBUG_DEPENDENCIES ) \
  $( [ ${INSTALL_DEPENDENCIES_FROM_PACKAGE} = 1 ] && echo $DEPENDENCIES )

# Build the module.
COPY lib /anesowa/lib
COPY sound-player/CMakeLists.txt ./
COPY sound-player/src ./src

# docker run ... --target dev
FROM base as development

RUN cmake -S . -B build -DTARGET_GROUP=development --fresh
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
ARG INSTALL_DEPENDENCIES_FROM_PACKAGE
ENV INSTALL_DEPENDENCIES_FROM_PACKAGE=$INSTALL_DEPENDENCIES_FROM_PACKAGE

COPY sound-player/tests ./tests

# TODO: BUILD_DEPENDENCY_TESTS will fail because various dependencies define the "unity"
# target (unity is the testing framework). I asked the question to the community:
#
# Building Project with Depedencies’ Tests: CMake FetchContent Conflicting Targets:
#
# - StackOverflow 
#   https://stackoverflow.com/questions/77739155
#
# - CMake Discourse
#   https://discourse.cmake.org/t/building-project-with-depedencies-tests-cmake-fetchcontent-conflicting-targets/9747
#
# RUN cmake -S . -B build -DTARGET_GROUP=test -DBUILD_DEPENDENCY_TESTS=1
RUN cmake -S . -B build -DTARGET_GROUP=test -DBUILD_DEPENDENCY_TESTS=0
RUN cmake --build build --verbose

ENTRYPOINT [ "ctest", "--test-dir", "build", "--verbose" ]

# docker run ... --target prod
FROM base as production

RUN cmake -S . -B build -DTARGET_GROUP=production
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
  echo $BUILD_TIME_DEPENDENCIES | sed -e 's/=[^ =]*//g' | xargs apk del; \
  fi

ENTRYPOINT [ "./sound-player" ]
