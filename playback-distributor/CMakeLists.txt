cmake_minimum_required(VERSION 3.10)

project(playback-distributor)

if(NOT DEFINED TARGET_GROUP)
  message(
    FATAL_ERROR
    "Missing TARGET_GROUP when configuring CMake project, "
    "pass it on the cmake command as -DTARGET_GROUP=[production | development | test]."
  )
endif()

# NOTE: Must be included at the top so any call to add_test by subproject and third
# party dependencies get included and simply running `ctest` on the build folder would
# run them all.
if(TARGET_GROUP STREQUAL test)
  include(CTest)
endif()

# Produces the JSON Compilation Database (`compile_commands.json`) used by clangd (the 
# C++ language server) so it works with Neovim's language server feature:
#
#   https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#clangd
#
# NOTE: This needs to be in every CMake project.
#
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Shared dependencies: Add anesowa common library and include paths.
set(WANTS_CJSON ON)

# By linking to anesowa-common after the WANTS_CJSON, WANTS_PULSEAUDIO, ... options
# there's no further need to link or add include directories for cJSON, PulseAudio
# since it will be provided through the anesowa-commons lib. See the CMakeLists.txt on
# `lib/c/commons/CMakeLists.txt`.
add_subdirectory(../lib/c/commons anesowa-commons)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../lib/c/commons/include)

if(TARGET_GROUP STREQUAL production OR TARGET_GROUP STREQUAL development)
  # Add and link our executable to the libraries it needs.
  set(PLAYBACK_DISTRIBUTOR_SOURCE_FILES src/playback_distributor.c)
  add_executable(${PROJECT_NAME} ${PLAYBACK_DISTRIBUTOR_SOURCE_FILES})
  target_link_libraries(${PROJECT_NAME} anesowa-commons)
endif()

if(TARGET_GROUP STREQUAL test)
  # Configure the suite and tests to be run from CMake as `ctest --test-dir build --verbose`.
  add_executable(suite-${PROJECT_NAME} test/test_playback_distributor.c)
  target_link_libraries(suite-${PROJECT_NAME} anesowa-commons)
  add_test(test-${PROJECT_NAME} suite-${PROJECT_NAME})
endif()
