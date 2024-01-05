cmake_minimum_required(VERSION 3.10)

# Avoid warning about DOWNLOAD_EXTRACT_TIMESTAMP in CMake 3.24:
if (CMAKE_VERSION VERSION_GREATER_EQUAL 3.24)
  cmake_policy(SET CMP0135 NEW)
endif()

project(anesowa-commons)

include(CMakePrintHelpers)
include(ExternalProject)
include(helpers.cmake)

# Produces the JSON Compilation Database (`compile_commands.json`) used by clangd (the 
# C++ language server) so it works with Neovim's language server feature:
#
#   https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#clangd
#
# NOTE: This needs to be in every CMake project.
#
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# The Dockerfile sets this environment variable. Not using a CMake flag to show that we
# can also use environment variables, although it might not conform to common practices.
set(DEPENDENCIES_COMPILE_FROM_SOURCE ON)
if(DEFINED ENV{DEPENDENCIES_COMPILE_FROM_SOURCE})
  set(DEPENDENCIES_COMPILE_FROM_SOURCE $ENV{DEPENDENCIES_COMPILE_FROM_SOURCE})
endif()

cmake_print_variables(TARGET_GROUP)
if(BUILD_TYPE STREQUAL test)
  set(IS_TEST_BUILD ON)
else()
  set(IS_TEST_BUILD OFF)
endif()

# Create the project's library.
set(COMMONS_UTILS_SOURCE_FILES src/utils.c)
add_library(${PROJECT_NAME} ${COMMONS_UTILS_SOURCE_FILES})

# cmocka
if(IS_TEST_BUILD)
  if(COMPILE_DEPS_FROM_SOURCE)
    message("[Dependency] [cmocka] Compile from source.")
    ExternalProject_Add(
      cmocka
      URL https://cmocka.org/files/1.1/cmocka-1.1.7.tar.xz
      URL_HASH MD5=dc23f4870eb7dfa6da065f3056e815b0
      CMAKE_ARGS -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_BINARY_DIR}/cmocka
      CMAKE_CACHE_ARGS
        -DUNIT_TESTING:BOOL=TRUE
        -DWITH_EXAMPLES:BOOL=FALSE
    )
    list(APPEND ${PROJECT_NAME}_external_project_added_test_dependencies cmocka)
  else()
    message("[Dependency] [cmocka] Use from package.")
    find_package(cmocka REQUIRED)
    target_link_libraries(${PROJECT_NAME} PUBLIC cmocka::cmocka)
  endif()
endif()

# ZeroMQ
if(DEPENDENCIES_COMPILE_FROM_SOURCE)
  message("[Dependency] [ZeroMQ] Compile from source.")
  ExternalProject_Add(
    zmq
    URL https://github.com/zeromq/libzmq/archive/refs/tags/v4.3.5.tar.gz
    URL_HASH MD5=cfb80c6ad694cacc2f7c99bf44e8b686
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_BINARY_DIR}/zmq
    CMAKE_CACHE_ARGS -DBUILD_TESTS:BOOL=${IS_TEST_BUILD}
  )
  list(APPEND ${PROJECT_NAME}_external_project_added_dependencies zmq)
else()
  message("[Dependency] [ZeroMQ] Using from installed package.")
  find_package(PkgConfig REQUIRED)
  pkg_search_module(ZMQ REQUIRED libzmq)
  target_include_directories(${PROJECT_NAME} PUBLIC ${ZMQ_INCLUDE_DIRS})
  target_link_libraries(${PROJECT_NAME} PUBLIC ${ZMQ_LINK_LIBRARIES})
endif()

# PulseAudio
if(WANTS_PULSEAUDIO)
  message("[Dependency] [PulseAudio] Using from installed package.")
  find_package(PulseAudio REQUIRED)
  find_library(PULSEAUDIO_SIMPLE_LIBRARY pulse-simple REQUIRED)
  target_include_directories(${PROJECT_NAME} PUBLIC ${PULSEAUDIO_INCLUDE_DIR})
  target_link_libraries(${PROJECT_NAME} PUBLIC ${PULSEAUDIO_LIBRARY} ${PULSEAUDIO_SIMPLE_LIBRARY})
endif()

# cJSON
if(WANTS_CJSON)
  if(DEPENDENCIES_COMPILE_FROM_SOURCE)
    message("[Dependency] [cjson] Compile from source.")
    ExternalProject_Add(
      cjson
      URL https://github.com/DaveGamble/cJSON/archive/refs/tags/v1.7.16.tar.gz
      URL_HASH MD5=9422f73fb9e4e524d77d9467d4b73536
      CMAKE_ARGS -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_BINARY_DIR}/cjson
      CMAKE_CACHE_ARGS
        -DENABLE_CJSON_TEST:BOOL=${IS_TEST_BUILD}
    )
    list(APPEND ${PROJECT_NAME}_external_project_added_dependencies cjson)
  else()
    message("[Dependency] [cjson] Using from installed package.")
    find_package(cJSON REQUIRED)
    target_link_libraries(${PROJECT_NAME} PUBLIC cjson)
  endif()
endif()

# Link all dependencies to the shared "anesowa-commons" library so the other projects
# by simply linking to "anesowa-commons" will receive "anesowa-commons"' dependencies
# as well.
#
# Individual targets for anesowa-commons' dependencies will also be available as their
# lowercased name prefixed with `lib_`, e.g.: `lib_cjson`, `lib_cmocka`. Those `lib_*`
# targets will only be available when compiling from source, if using the packaged
# versions the <DEP>_INCLUDE_DIRS, <DEP>_LIBRARIES, ... will be available since CMake
# instead of compiling from source would have used `find_package()` calls.
if(DEPENDENCIES_COMPILE_FROM_SOURCE)
  foreach(
      dep IN LISTS
      ${PROJECT_NAME}_external_project_added_dependencies
      ${PROJECT_NAME}_external_project_added_test_dependencies
  )
    add_dependencies(${PROJECT_NAME} ${dep})

    add_library(${dep}_lib INTERFACE)
    target_include_directories(
      ${dep}_lib
      INTERFACE
      ${CMAKE_BINARY_DIR}/${dep}/include/
    )
    target_link_libraries(
      ${dep}_lib
      INTERFACE
      ${CMAKE_BINARY_DIR}/${dep}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}${dep}${CMAKE_SHARED_LIBRARY_SUFFIX}
    )
  endforeach()

  foreach(
      dep IN LISTS
      ${PROJECT_NAME}_external_project_added_dependencies
  )
    # Link against the interface lib, that way instead of having to run:
    #
    #   `target_include_directories(foo ${CMAKE_BINARY_DIR}/zmq/include/)`
    #   `target_link_libraries(foo ${CMAKE_BINARY_DIR}/zmq/lib/libzmq.so)`
    #
    # we can simply link to the interface library which has this information (includes and
    # libs) associated:
    #
    #   `target_link_libraries(foo zmq_lib)`
    #
    # That makes it cleaner when we have to link to these deps on other executables or unit tests.
    target_link_libraries(${PROJECT_NAME} PUBLIC ${dep}_lib)
  endforeach()
endif()

if(IS_TEST_BUILD)
  set(
    ${PROJECT_NAME}_unit_tests
    test_utils
  )
  foreach(${PROJECT_NAME}_unit_test ${${PROJECT_NAME}_unit_tests})
    add_executable(${${PROJECT_NAME}_unit_test} tests/${${PROJECT_NAME}_unit_test}.c)
    target_link_libraries(${${PROJECT_NAME}_unit_test} PUBLIC ${PROJECT_NAME})
    add_test(${${PROJECT_NAME}_unit_test} ${${PROJECT_NAME}_unit_test})
  endforeach()
endif()

