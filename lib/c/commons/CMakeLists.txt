cmake_minimum_required(VERSION 3.10)

project(anesowa-commons)

include(CMakePrintHelpers)

# Produces the JSON Compilation Database (`compile_commands.json`) used by clangd (the 
# C++ language server) so it works with Neovim's language server feature:
#
#   https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#clangd
#
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(CMakePrintHelpers)

# Third party: ZeroMQ.
find_package(PkgConfig REQUIRED)
pkg_search_module(ZMQ REQUIRED libzmq)
cmake_print_variables(ZMQ_INCLUDE_DIRS)
cmake_print_variables(ZMQ_LINK_LIBRARIES)
include_directories(${ZMQ_INCLUDE_DIRS})

# Third party: cJSON.
if(WANTS_CJSON)
  find_package(cJSON)
  cmake_print_variables(cJSON_FOUND)
  if(NOT cJSON_FOUND)
    include(FetchContent)
    FetchContent_Declare(
      cJSON
      GIT_REPOSITORY https://github.com/DaveGamble/cJSON
      GIT_TAG        cb8693b058ba302f4829ec6d03f609ac6f848546 # v1.7.16
    )
    set(ENABLE_CJSON_TEST OFF CACHE BOOL "cJSON: Build with unit testing" FORCE)
    FetchContent_MakeAvailable(cJSON)
  endif()

  cmake_print_variables(CJSON_INCLUDE_DIRS)
  cmake_print_variables(CJSON_LIBRARIES)
  include_directories(${CJSON_INCLUDE_DIRS})
endif()

if(WANTS_PULSEAUDIO)
  # Third party: PulseAudio (Core & Simple API).
  find_package(PulseAudio)
  include_directories(${PULSEAUDIO_INCLUDE_DIR})
  find_library(PULSEAUDIO_SIMPLE_LIBRARY pulse-simple)
  cmake_print_variables(PULSEAUDIO_LIBRARY)
  cmake_print_variables(PULSEAUDIO_SIMPLE_LIBRARY)
endif()

# Prepare the sources to include in the library.
include_directories(./include)
set(COMMONS_UTILS_SOURCE_FILES src/utils.c)

# Create the library.
add_library(${PROJECT_NAME} ${COMMONS_UTILS_SOURCE_FILES})
target_link_libraries(${PROJECT_NAME} ${ZMQ_LINK_LIBRARIES})
