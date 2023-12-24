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

if(TARGET_GROUP STREQUAL development OR TARGET_GROUP STREQUAL test)
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
add_subdirectory(../lib/c/commons anesowa-commons)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../lib/c/commons/include)

# Third party: cJSON.
find_package(cJSON)
cmake_print_variables(CJSON_INCLUDE_DIRS)
cmake_print_variables(CJSON_LIBRARIES)
include_directories(${CJSON_INCLUDE_DIRS})

# Third party: ZeroMQ.
find_package(PkgConfig REQUIRED)
pkg_search_module(ZMQ REQUIRED libzmq)
cmake_print_variables(ZMQ_INCLUDE_DIRS)
cmake_print_variables(ZMQ_LINK_LIBRARIES)
include_directories(${ZMQ_INCLUDE_DIRS})

if(TARGET_GROUP STREQUAL production OR TARGET_GROUP STREQUAL development)
  # Add and link our executable to the libraries it needs.
  set(PLAYBACK_DISTRIBUTOR_SOURCE_FILES src/playback_distributor.c)
  add_executable(${PROJECT_NAME} ${PLAYBACK_DISTRIBUTOR_SOURCE_FILES})
  target_link_libraries(${PROJECT_NAME} anesowa-commons)
  target_link_libraries(${PROJECT_NAME} ${CJSON_LIBRARIES})
  target_link_libraries(${PROJECT_NAME} ${ZMQ_LINK_LIBRARIES})
endif()

if(TARGET_GROUP STREQUAL test)
  # Configure unit tests.
  #
  # Sources:
  # - https://honeytreelabs.com/posts/cmake-unity-integration/
  # - https://docs.docker.com/language/nodejs/run-tests/
  #

  # Add Third-Party Unity (unit testing framework).
  include(FetchContent)
  FetchContent_Declare(
    unity
    GIT_REPOSITORY https://github.com/ThrowTheSwitch/Unity
    GIT_TAG        0b899aec14d3a9abb2bf260ac355f0f28630a6a3 # v2.5.2
  )
  FetchContent_MakeAvailable(unity)

  # Include ctest (built-in CMake test runner).
  include(CTest)

  # Configure the suit and tests to be run from CMake as `ctest --test-dir build --verbose`.
  add_executable(suite-${PROJECT_NAME} test/test_playback_distributor.c)
  target_link_libraries(suite-${PROJECT_NAME} unity)
  add_test(test-${PROJECT_NAME} suite-${PROJECT_NAME})
endif()
