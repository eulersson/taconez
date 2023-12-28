cmake_minimum_required(VERSION 3.10)

project(sound-player)

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

# Shared dependencies: Add anesowa common library and include paths.
set(WANTS_CJSON ON)
set(WANTS_PULSEAUDIO ON)
set(WANTS_ZMQ ON)
add_subdirectory(../lib/c/commons anesowa_commons)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../lib/c/commons/include)

if(TARGET_GROUP STREQUAL production OR TARGET_GROUP STREQUAL development)
  # Add and link our executable to the libraries it needs.
  set(SOUND_PLAYER_SOURCE_FILES src/sound_player.c)
  add_executable(${PROJECT_NAME} ${SOUND_PLAYER_SOURCE_FILES})
  target_link_libraries(${PROJECT_NAME} anesowa-commons)
  target_link_libraries(${PROJECT_NAME} ${CJSON_LIBRARY})
  target_link_libraries(${PROJECT_NAME} ${PULSEAUDIO_LIBRARY})
  target_link_libraries(${PROJECT_NAME} ${PULSEAUDIO_SIMPLE_LIBRARY})
  target_link_libraries(${PROJECT_NAME} ${ZMQ_LINK_LIBRARIES})
endif()

if(TARGET_GROUP STREQUAL test)
  # Download cmocka, a unit test framework with mocking capabilities.
  include(FetchContent)
  FetchContent_Declare(
    cmocka
    GIT_REPOSITORY https://git.cryptomilk.org/projects/cmocka.git
    GIT_TAG        5838210b437c7abf688e74bcf057ad9e6d637ee6 # cmocka-1.1.7
    GIT_SHALLOW    1
  )
  set(WITH_EXAMPLES OFF CACHE BOOL "CMocka: Build examples" FORCE)
  set(UNIT_TESTING OFF CACHE BOOL "CMocka: Build with unit testing" FORCE)
  FetchContent_MakeAvailable(cmocka)

  # Include ctest (built-in CMake test runner).
  include(CTest)

  # Configure the suite and tests to be run from CMake as `ctest --test-dir build --verbose`.
  add_executable(suite-${PROJECT_NAME} test/test_sound_player.c)
  target_link_libraries(suite-${PROJECT_NAME} cmocka)
  add_test(test-${PROJECT_NAME} suite-${PROJECT_NAME})
endif()
