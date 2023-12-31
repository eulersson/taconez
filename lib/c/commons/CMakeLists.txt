cmake_minimum_required(VERSION 3.10)

# Avoid warning about DOWNLOAD_EXTRACT_TIMESTAMP in CMake 3.24:
if (CMAKE_VERSION VERSION_GREATER_EQUAL 3.24)
  cmake_policy(SET CMP0135 NEW)
endif()

project(anesowa-commons)

# Produces the JSON Compilation Database (`compile_commands.json`) used by clangd (the 
# C++ language server) so it works with Neovim's language server feature:
#
#   https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#clangd
#
# NOTE: This needs to be in every CMake project.
#
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Create the library.
set(COMMONS_UTILS_SOURCE_FILES src/utils.c)
add_library(${PROJECT_NAME} ${COMMONS_UTILS_SOURCE_FILES})

if($ENV{INSTALL_DEPENDENCIES_FROM_PACKAGE})
  message("Using ZeroMQ from package.")
  # Third party: ZeroMQ.
  find_package(PkgConfig REQUIRED)
  pkg_search_module(ZMQ REQUIRED libzmq)
  include(CMakePrintHelpers)
  target_include_directories(${PROJECT_NAME} PUBLIC ${ZMQ_INCLUDE_DIRS})
  target_link_libraries(${PROJECT_NAME} PUBLIC ${ZMQ_STATIC_LIBRARIES})
else()
  message("Building ZeroMQ from source.")
  include(FetchContent)

  message("Fetching ZeroMQ tarball.")
  FetchContent_Declare(
    libzmq
    URL https://github.com/zeromq/libzmq/archive/refs/tags/v4.3.4.tar.gz
    URL_HASH MD5=cc20b769ac10afa352e5ed2769bb23b3
  )

  if(BUILD_DEPENDENCY_TESTS)
    message("Will include ZeroMQ's unit tests.")
    set(BUILD_TESTS ON CACHE BOOL "libzmq: Build unit tests" FORCE)
  else()
    message("Won't include ZeroMQ's unit tests.")
    set(BUILD_TESTS OFF CACHE BOOL "libzmq: Build unit tests" FORCE)
  endif()

  FetchContent_MakeAvailable(libzmq)
  target_link_libraries(${PROJECT_NAME} PUBLIC libzmq-static)
endif()

# Third party: cJSON.
if(WANTS_CJSON)
  if($ENV{INSTALL_DEPENDENCIES_FROM_PACKAGE})
    message("Using cJSON from package.")
    find_package(cJSON REQUIRED)
    target_include_directories(${PROJECT_NAME} PUBLIC ${CJSON_INCLUDE_DIRS})
    target_link_libraries(${PROJECT_NAME} PUBLIC ${CJSON_STATIC_LIBRARIES})
  else()
    message("Building cJSON from source.")
    include(FetchContent)
    message("Fetching cJSON tarball.")
    FetchContent_Declare(
      cJSON
      URL https://github.com/DaveGamble/cJSON/archive/refs/tags/v1.7.15.tar.gz
      URL_HASH MD5=921b4bcb401aa604dc632fdb1c8dbdea
    )

    if(BUILD_DEPENDENCY_TESTS)
      message("Will include cJSON's unit tests.")
      set(ENABLE_CJSON_TEST ON CACHE BOOL "cJSON: Build unit tests" FORCE)
    else()
      message("Won't include cJSON's unit tests.")
      set(ENABLE_CJSON_TEST OFF CACHE BOOL "cJSON: Build unit tests" FORCE)
    endif()
    FetchContent_MakeAvailable(cJSON)
    # TODO: Check if this is the best way to make a header available at build time to
    # not have to install cJSON system-wide. The cjson target does not include the
    # header file.
    #
    # - Installing with CMake's FetchContent creates problems with header files
    #   https://github.com/DaveGamble/cJSON/issues/816
    #
    # - [FetchContent] How to include header files of a third-party project whose target does not provide them
    #   https://discourse.cmake.org/t/fetchcontent-how-to-include-header-files-of-a-third-party-project-whose-target-does-not-provide-them/9734
    # 
    configure_file(${cJSON_SOURCE_DIR}/cJSON.h ${CMAKE_BINARY_DIR}/include/cjson/cJSON.h)
    target_include_directories(${PROJECT_NAME} PUBLIC ${CMAKE_BINARY_DIR}/include)
    target_link_libraries(${PROJECT_NAME} PUBLIC cjson) # It's lowercase as you can see in https://github.com/DaveGamble/cJSON/blob/v1.7.15/CMakeLists.txt#L117
  endif()
endif()

# TODO: Handle the package vs compile from source logic.
if(WANTS_PULSEAUDIO)
  # Third party: PulseAudio (Core API).
  find_package(PulseAudio REQUIRED)

  # # Third party: PulseAudio (Simple API).
  find_library(PULSEAUDIO_SIMPLE_LIBRARY pulse-simple REQUIRED)

  # Prepare the sources to include in the target.
  target_include_directories(${PROJECT_NAME} PUBLIC ${PULSEAUDIO_INCLUDE_DIR})
  target_link_libraries(${PROJECT_NAME} PUBLIC ${PULSEAUDIO_LIBRARY} ${PULSEAUDIO_SIMPLE_LIBRARY})
endif()

# Third party: cmocka (unit test framework with mocking capabilities).
if(TARGET_GROUP STREQUAL test)
  include(FetchContent)

  FetchContent_Declare(
    cmocka
    URL https://cmocka.org/files/1.1/cmocka-1.1.7.tar.xz
    URL_HASH MD5=dc23f4870eb7dfa6da065f3056e815b0
  )

  set(WITH_EXAMPLES OFF CACHE BOOL "CMocka: Build examples" FORCE)

  # Since cmocka includes the `unity` target it would clash if we build unit tests for
  # all dependencies.
  #
  #   - How can I avoid clashes with targets "imported" with FetchContent_MakeAvailable?
  #     https://stackoverflow.com/a/72943178
  #
  if(BUILD_DEPENDENCY_TESTS)
    message("Will include cmocka unit tests.")
    set(UNIT_TESTING ON CACHE BOOL "CMocka: Build unit tests" FORCE)
  else()
    message("Won't include cmocka unit tests.")
    set(UNIT_TESTING OFF CACHE BOOL "CMocka: Build unit tests" FORCE)
  endif()

  FetchContent_MakeAvailable(cmocka)
  target_link_libraries(${PROJECT_NAME} PUBLIC cmocka::cmocka)

  if(TARGET_GROUP STREQUAL test)
    add_subdirectory(tests)
  endif()
endif()
