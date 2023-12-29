cmake_minimum_required(VERSION 3.10)

project(anesowa-commons)

include(CMakePrintHelpers)

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

# Third party: ZeroMQ.
find_package(PkgConfig REQUIRED)
pkg_search_module(ZMQ REQUIRED libzmq)
cmake_print_variables(ZMQ_INCLUDE_DIRS)
cmake_print_variables(ZMQ_LIBRARIES)
cmake_print_variables(ZMQ_LINK_LIBRARIES)

# Include directories and link target so dependants would also have ZeroMQ.
target_include_directories(${PROJECT_NAME} PUBLIC ${ZMQ_INCLUDE_DIRS})
target_link_libraries(${PROJECT_NAME} PUBLIC ${ZMQ_LINK_LIBRARIES})

# Third party: cJSON.
if(WANTS_CJSON)
  find_package(cJSON)
  if(cJSON_FOUND)
    message("cJSON was found on the system! No need to build it.")
    target_include_directories(${PROJECT_NAME} PUBLIC ${CJSON_INCLUDE_DIRS})
    target_link_libraries(${PROJECT_NAME} PUBLIC ${CJSON_LIBRARIES})
  else()
    message("cJSON was not found on the system! Fetching and building it...")

    include(FetchContent)

    FetchContent_Declare(
      cJSON
      GIT_REPOSITORY https://github.com/DaveGamble/cJSON
      GIT_TAG        cb8693b058ba302f4829ec6d03f609ac6f848546 # v1.7.16
    )
    set(ENABLE_CJSON_TEST OFF CACHE BOOL "cJSON: Build with unit testing" FORCE)
    FetchContent_MakeAvailable(cJSON)

    get_cmake_property(_variableNames VARIABLES)

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
    configure_file(${cJSON_SOURCE_DIR}/cJSON.h ${CMAKE_BINARY_DIR}/include/cJSON/cJSON.h)
    target_include_directories(${PROJECT_NAME} PUBLIC ${CMAKE_BINARY_DIR}/include)
    target_link_libraries(${PROJECT_NAME} PUBLIC cjson)
  endif()
endif()

if(WANTS_PULSEAUDIO)
  # Third party: PulseAudio (Core API).
  find_package(PulseAudio)

  cmake_print_variables(PULSEAUDIO_INCLUDE_DIR)
  cmake_print_variables(PULSEAUDIO_LIBRARY)

  # # Third party: PulseAudio (Simple API).
  find_library(PULSEAUDIO_SIMPLE_LIBRARY pulse-simple)
  cmake_print_variables(PULSEAUDIO_SIMPLE_LIBRARY)

  # Prepare the sources to include in the target.
  target_include_directories(${PROJECT_NAME} PUBLIC ${PULSEAUDIO_INCLUDE_DIR})
  target_link_libraries(${PROJECT_NAME} PUBLIC ${PULSEAUDIO_LIBRARY} ${PULSEAUDIO_SIMPLE_LIBRARY})
endif()

# Third party: cmocka (unit test framework with mocking capabilities).
if(TARGET_GROUP STREQUAL test)
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
  target_link_libraries(${PROJECT_NAME} PUBLIC cmocka::cmocka)
endif()
