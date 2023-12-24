#!/bin/sh
#
# Generates the CMake project and builds the binaries.
#
# Usage:
#
#   build-cmake-project.sh -DTARGET_GROUP=development|production|test [-DEXTRA_CMAKE_FLAG_1=val1, -DEXTRA_CMAKE_FLAG_2=val2 ...]
#

cmake -S . -B build $@ --fresh && cmake --build build --verbose
