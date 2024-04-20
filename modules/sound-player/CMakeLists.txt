cmake_minimum_required(VERSION 3.10)

# Avoid warning about DOWNLOAD_EXTRACT_TIMESTAMP in CMake 3.24:
if (CMAKE_VERSION VERSION_GREATER_EQUAL 3.24)
  cmake_policy(SET CMP0135 NEW)
endif()

project(sound-player)

set(TACONEZ_COMMONS_DIR ${PROJECT_SOURCE_DIR}/../lib/c/commons)

# NOTE: Must be included at the top so any call to add_test by subproject and third
# party dependencies get included and simply running `ctest` on the build folder would
# run them all.
option(TACONEZ_BUILD_TESTS "Build playback distribution tests" OFF)
if(TACONEZ_BUILD_TESTS)
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

# Shared dependencies: Add taconez common library and include paths.
set(WANTS_PULSEAUDIO ON)

# By linking to taconez-common after the WANTS_CJSON, WANTS_PULSEAUDIO, ... options
# there's no further need to link or add include directories for cJSON, PulseAudio, ...
# since it will be provided through the taconez_commons lib. See the CMakeLists.txt on
# `lib/c/commons/CMakeLists.txt`.
add_subdirectory(${TACONEZ_COMMONS_DIR} taconez_commons)

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
add_executable(sound-player ${SOUND_PLAYER_SOURCE_FILES})
target_include_directories(sound-player PRIVATE src)
target_link_libraries(sound-player PRIVATE taconez_commons)

# Install playback_distributor binary and all its dependencies so it can run outside the
# build folder.
install(TARGETS sound-player)
install(DIRECTORY ${CMAKE_BINARY_DIR}/zmq/include DESTINATION ${CMAKE_INSTALL_PREFIX})
install(DIRECTORY ${CMAKE_BINARY_DIR}/zmq/lib DESTINATION ${CMAKE_INSTALL_PREFIX})
install(DIRECTORY ${CMAKE_BINARY_DIR}/cjson/include DESTINATION ${CMAKE_INSTALL_PREFIX})
install(DIRECTORY ${CMAKE_BINARY_DIR}/cjson/lib DESTINATION ${CMAKE_INSTALL_PREFIX})

# We don't simply link taconez_commons to the test target because we might want to mock
# some of its functions, that means we have to exclude the mocked code from the sources.
if(TACONEZ_BUILD_TESTS)
  set(
    PROJECT_TESTS
    test_sound_player
  )

  set(PROJECT_TESTS_INCLUDE_DIRS
    ${TACONEZ_COMMONS_DIR}/include
    ${TACONEZ_COMMONS_DIR}/include/taconez/commons
  )

  # Add sources removing mocked code to avoid "duplicate symbol" linking errors.
  file(GLOB sources RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} src/*.c)
  list(
    REMOVE_ITEM
    sources
    src/sound_player.c
    src/play.c
  )

  # Add common sources removing mocked code to avoid "duplicate symbol" linking errors.
  set(commons_sources ${COMMONS_SOURCE_FILES})
  list(
    REMOVE_ITEM
    commons_sources
    src/socket.c
  )
  list(TRANSFORM commons_sources PREPEND "${TACONEZ_COMMONS_DIR}/")

  foreach(test_name ${PROJECT_TESTS})
    create_test(${test_name} tests/${test_name}.c)
    target_include_directories(
      ${test_name}
      PRIVATE
      ${PROJECT_TESTS_INCLUDE_DIRS}
    )
    target_include_directories(${test_name} PRIVATE src)
    target_link_libraries(${test_name} PRIVATE cjson_lib pulseaudio_lib)
    target_sources(${test_name} PRIVATE ${sources} ${commons_sources})
  endforeach()
endif()
