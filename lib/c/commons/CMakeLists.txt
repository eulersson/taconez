cmake_minimum_required(VERSION 3.10)

# Avoid warning about DOWNLOAD_EXTRACT_TIMESTAMP in CMake 3.24:
if (CMAKE_VERSION VERSION_GREATER_EQUAL 3.24)
  cmake_policy(SET CMP0135 NEW)
endif()

project(anesowa_commons)

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
  set(IS_TEST_BUILD ON)
  include(CTest)
  enable_testing()
else()
  set(IS_TEST_BUILD OFF)
endif()

if(PROJECT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
  set(VENDOR_DIR ${CMAKE_CURRENT_SOURCE_DIR}/vendor)
endif()

include(CMakePrintHelpers)
include(ExternalProject)
include(FetchContent)
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

# Create the project's library.
set(
  COMMONS_UTILS_SOURCE_FILES
  src/multiplier.c
  src/utils.c
)
add_library(anesowa_commons ${COMMONS_UTILS_SOURCE_FILES})
target_include_directories(anesowa_commons PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

# Unity & fff (Testing Utilities)
if(IS_TEST_BUILD)
  if(NOT EXISTS ${VENDOR_DIR}/Unity/src OR NOT EXISTS ${VENDOR_DIR}/cmock/src)
    message(
      FATAL_ERROR
      "Vendor code not available, you must clone the repository with: `git clone "
      "--recurse-submodules`, if not please run `git submodule update --init --recursive`"
    )
  endif()

  message("[Dependency] [Unity] Compile from source.")
  add_library(unity_lib ${VENDOR_DIR}/Unity/src/unity.c)
  target_include_directories(unity_lib PUBLIC vendor/Unity/src/)
  target_link_libraries(anesowa_commons PUBLIC unity_lib)

  FetchContent_Declare(
    fff # Fake Function Framework (fff)
    GIT_REPOSITORY https://github.com/meekrosoft/fff.git
    GIT_TAG 5111c61e1ef7848e3afd3550044a8cf4405f4199 # A stable commit in master.
  )
  FetchContent_MakeAvailable(fff)
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
  list(APPEND anesowa_commons_external_project_added_dependencies zmq)
else()
  message("[Dependency] [ZeroMQ] Using from installed package.")

  find_package(PkgConfig REQUIRED)
  pkg_search_module(ZMQ REQUIRED libzmq)

  add_library(zmq_lib INTERFACE)
  target_include_directories(zmq_lib INTERFACE ${ZMQ_INCLUDE_DIRS})
  target_link_libraries(zmq_lib INTERFACE ${ZMQ_LINK_LIBRARIES})

  target_link_libraries(anesowa_commons PUBLIC zmq_lib)

endif()

# PulseAudio
if(WANTS_PULSEAUDIO)
  message("[Dependency] [PulseAudio] Using from installed package.")
  find_package(PulseAudio REQUIRED)
  find_library(PULSEAUDIO_SIMPLE_LIBRARY pulse-simple REQUIRED)
  target_include_directories(anesowa_commons PUBLIC ${PULSEAUDIO_INCLUDE_DIR})
  target_link_libraries(anesowa_commons PUBLIC ${PULSEAUDIO_LIBRARY} ${PULSEAUDIO_SIMPLE_LIBRARY})
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
    list(APPEND anesowa_commons_external_project_added_dependencies cjson)
  else()
    message("[Dependency] [cjson] Using from installed package.")
    find_package(cJSON REQUIRED)
    target_link_libraries(anesowa_commons PUBLIC cjson)
  endif()
endif()

# Link all dependencies to the shared "anesowa_commons" library so the other projects
# by simply linking to "anesowa_commons" will receive "anesowa_commons"' dependencies
# as well.
#
# Individual targets for anesowa_commons' dependencies will also be available as their
# lowercased name prefixed with `lib_`, e.g.: `lib_cjson`, `lib_zmq`. Those `lib_*`
# targets will only be available when compiling from source, if using the packaged
# versions the <DEP>_INCLUDE_DIRS, <DEP>_LIBRARIES, ... will be available since CMake
# instead of compiling from source would have used `find_package()` calls.
if(DEPENDENCIES_COMPILE_FROM_SOURCE)
  foreach(dep ${anesowa_commons_external_project_added_dependencies})
    add_dependencies(anesowa_commons ${dep}) # otherwise does not download sources
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
    target_link_libraries(anesowa_commons PUBLIC ${dep}_lib)
  endforeach()
endif()

if(IS_TEST_BUILD)
  # Create the tests.
  create_test(test_utils tests/test_utils.c)
  target_include_directories(test_utils PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
  target_link_libraries(test_utils PRIVATE zmq_lib)

  # Add sources removing mocked code to avoid "duplicate symbol" linking errors.
  file(GLOB sources RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} src/*.c)
  list(REMOVE_ITEM sources src/potato.c)
  target_sources(test_utils PRIVATE ${sources})
endif()
