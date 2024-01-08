cmake_minimum_required(VERSION 3.10)

# Avoid warning about DOWNLOAD_EXTRACT_TIMESTAMP in CMake 3.24:
if (CMAKE_VERSION VERSION_GREATER_EQUAL 3.24)
  cmake_policy(SET CMP0135 NEW)
endif()

project(sound_player)

if(NOT DEFINED BUILD_TYPE)
  message(
    FATAL_ERROR
    "Missing BUILD_TYPE when configuring CMake project, "
    "pass it on the cmake command as -DBUILD_TYPE=[production | development | test]."
  )
endif()

set(ANESOWA_COMMONS_DIR ${PROJECT_SOURCE_DIR}/../lib/c/commons)

# NOTE: Must be included at the top so any call to add_test by subproject and third
# party dependencies get included and simply running `ctest` on the build folder would
# run them all.
if(BUILD_TYPE STREQUAL test)
  include(CTest)
  enable_testing()
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
set(WANTS_PULSEAUDIO ON)

# By linking to anesowa-common after the WANTS_CJSON, WANTS_PULSEAUDIO, ... options
# there's no further need to link or add include directories for cJSON, PulseAudio, ...
# since it will be provided through the anesowa_commons lib. See the CMakeLists.txt on
# `lib/c/commons/CMakeLists.txt`.
add_subdirectory(${ANESOWA_COMMONS_DIR} anesowa_commons)

if(BUILD_TYPE STREQUAL production OR BUILD_TYPE STREQUAL development)
  set(
    SOUND_PLAYER_SOURCE_FILES
    src/sound_player.c
    src/play.h
    src/play.c
    src/process_loop.h
    src/process_loop.c
    src/time_utils.h
    src/time_utils.c
  )
  add_executable(sound_player ${SOUND_PLAYER_SOURCE_FILES})
  target_include_directories(playback_distributor PRIVATE src)
  target_link_libraries(sound_player PRIVATE anesowa_commons)
endif()

if(BUILD_TYPE STREQUAL test)
  # Create the tests.
  create_test(test_sound_player tests/test_sound_player.c)
  target_include_directories(
    test_sound_player
    PRIVATE
    ${ANESOWA_COMMONS_DIR}/include
  )
  target_link_libraries(test_sound_player PRIVATE zmq_lib)
  target_include_directories(test_sound_player PRIVATE src)

  # Add sources removing mocked code to avoid "duplicate symbol" linking errors.
  file(GLOB sources RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} src/*.c)
  list(REMOVE_ITEM sources src/playback_distributor.c)

  # Add common sources removing mocked code to avoid "duplicate symbol" linking errors.
  set(commons_sources ${COMMONS_SOURCE_FILES})
  list(REMOVE_ITEM commons_sources src/socket.c)
  list(TRANSFORM commons_sources PREPEND "${ANESOWA_COMMONS_DIR}/")

  target_sources(test_sound_player PRIVATE ${sources} ${commons_sources})
endif()
