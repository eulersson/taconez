cmake_minimum_required(VERSION 3.10)

project(sound-player)

if(NOT DEFINED BUILD_TYPE)
  message(
    FATAL_ERROR
    "Missing BUILD_TYPE when configuring CMake project, "
    "pass it on the cmake command as -DBUILD_TYPE=[production | development | test]."
  )
endif()

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
set(WANTS_CJSON ON)
set(WANTS_PULSEAUDIO ON)

# By linking to anesowa-common after the WANTS_CJSON, WANTS_PULSEAUDIO, ... options
# there's no further need to link or add include directories for cJSON, PulseAudio, ...
# since it will be provided through the anesowa-commons lib. See the CMakeLists.txt on
# `lib/c/commons/CMakeLists.txt`.
add_subdirectory(../lib/c/commons anesowa_commons)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../lib/c/commons/include)

if(BUILD_TYPE STREQUAL production OR BUILD_TYPE STREQUAL development)
  set(${PROJECT_NAME}_SOURCE_FILES src/sound_player.c)
  add_executable(${PROJECT_NAME} ${${PROJECT_NAME}_SOURCE_FILES})
  target_link_libraries(${PROJECT_NAME} anesowa-commons)
endif()

if(BUILD_TYPE STREQUAL test)
  set(
    ${PROJECT_NAME}_unit_tests
    test_sound_player
  )
  foreach(${PROJECT_NAME}_unit_test ${${PROJECT_NAME}_unit_tests})
    add_executable(${${PROJECT_NAME}_unit_test} tests/${${PROJECT_NAME}_unit_test}.c)
    target_link_libraries(${${PROJECT_NAME}_unit_test} PUBLIC anesowa-commons)
    add_test(${${PROJECT_NAME}_unit_test} ${${PROJECT_NAME}_unit_test})
  endforeach()
endif()
