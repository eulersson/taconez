cmake_minimum_required(VERSION 3.10)

project(sound-player)

if(NOT DEFINED TARGET_GROUP)
  message(
    FATAL_ERROR
    "Missing TARGET_GROUP when configuring CMake project, "
    "pass it on the cmake command as -DTARGET_GROUP=[production | development | test]."
  )
endif()

include(CMakePrintHelpers)

# Produces the JSON Compilation Database (`compile_commands.json`) used by clangd (the 
# C++ language server) so it works with Neovim's language server feature:
#
#   https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#clangd
#
# NOTE: This needs to be in every CMake project.
#
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

cmake_print_variables(CMAKE_CURRENT_LIST_DIR)
cmake_print_variables(CMAKE_CURRENT_SOURCE_DIR)

# Shared dependencies: Add anesowa common library and include paths.
set(WANTS_CJSON ON)
set(WANTS_PULSEAUDIO ON)

# By linking to anesowa-common after the WANTS_CJSON, WANTS_PULSEAUDIO, ... options
# there's no further need to link or add include directories for cJSON, PulseAudio
# since it will be provided through the anesowa-commons lib. See the CMakeLists.txt on
# `lib/c/commons/CMakeLists.txt`.
add_subdirectory(../lib/c/commons anesowa_commons)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../lib/c/commons/include)

if(TARGET_GROUP STREQUAL production OR TARGET_GROUP STREQUAL development)
  set(SOUND_PLAYER_SOURCE_FILES src/sound_player.c)
  add_executable(${PROJECT_NAME} ${SOUND_PLAYER_SOURCE_FILES})
  target_link_libraries(${PROJECT_NAME} anesowa-commons)
endif()

if(TARGET_GROUP STREQUAL test)
  # Configure the suite and tests to be run from CMake as `ctest --test-dir build --verbose`.
  add_executable(suite-${PROJECT_NAME} test/test_sound_player.c)
  target_link_libraries(suite-${PROJECT_NAME} anesowa-commons)

  # Include ctest (built-in CMake test runner).
  include(CTest)
  add_test(test-${PROJECT_NAME} suite-${PROJECT_NAME})
endif()
