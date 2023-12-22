cmake_minimum_required(VERSION 3.10)

project(playback-distributor)

include(CMakePrintHelpers)

if(NOT DEFINED TARGET_GROUP)
  message(
    FATAL_ERROR
    "Missing TARGET_GROUP when configuring CMake project, "
    "pass it on the cmake command as -DTARGET_GROUP=[production | development | test]."
  )
endif()

cmake_print_variables(CMAKE_CURRENT_LIST_DIR)
cmake_print_variables(CMAKE_CURRENT_SOURCE_DIR)

if(TARGET_GROUP STREQUAL development)
  # Produces the JSON Compilation Database (`compile_comands.json`) used by clangd (the 
  # C++ language server) so it works with Neovim's language server feature:
  #
  #   https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#clangd
  #
  set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
else()
  set(CMAKE_EXPORT_COMPILE_COMMANDS OFF)
endif()

cmake_print_variables(CMAKE_EXPORT_COMPILE_COMMANDS)

# Shared dependencies: Add anesowa common library and include paths.
add_subdirectory(../lib/c/commons anesowa_commons)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../lib/c/commons/include)

# Third party: ZeroMQ.
find_path(ZMQ_INCLUDE_DIR zmq.h)
cmake_print_variables(ZMQ_INCLUDE_DIR)
include_directories(${ZMQ_INCLUDE_DIR})

find_library(ZMQ_LIBRARY zmq)
cmake_print_variables(ZMQ_LIBRARY)

if(TARGET_GROUP STREQUAL production OR TARGET_GROUP STREQUAL development)
  # Link our executable to the libraries it needs.
  add_executable(playback-distributor src/playback_distributor.c)
  target_link_libraries(playback-distributor ${ZMQ_LIBRARY})
  target_link_libraries(playback-distributor anesowa_commons)
endif()

if(TARGET_GROUP STREQUAL test)
  # Configure unit tests.
  #
  # Sources:
  # - https://honeytreelabs.com/posts/cmake-unity-integration/
  # - https://docs.docker.com/language/nodejs/run-tests/
  #

  # Add Third-Party Unity (unit testing framework).
  add_subdirectory(../lib/c/Unity unity)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../lib/c/Unity/src)

  # Include ctest (built-in CMake test runner).
  include(CTest)

  add_executable(suite-hello test/test_hello.c)
  target_link_libraries(suite-hello unity)
  add_test(test-hello suite-hello)
endif()
