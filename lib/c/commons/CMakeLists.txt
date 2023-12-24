cmake_minimum_required(VERSION 3.10)

project(anesowa-commons)

# Produces the JSON Compilation Database (`compile_comands.json`) used by clangd (the 
# C++ language server) so it works with Neovim's language server feature:
#
#   https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#clangd
#

if(NOT DEFINED CMAKE_EXPORT_COMPILE_COMMANDS)
  set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
endif()

include(CMakePrintHelpers)

include_directories(./include)

# Third party: ZeroMQ.
find_package(PkgConfig REQUIRED)
pkg_search_module(ZMQ REQUIRED libzmq)
cmake_print_variables(ZMQ_INCLUDE_DIRS)
cmake_print_variables(ZMQ_LINK_LIBRARIES)
include_directories(${ZMQ_INCLUDE_DIRS})

# Prepare the sources to include in the library.
set(COMMONS_UTILS_SOURCE_FILES src/utils.c)

# Create the library.
add_library(${PROJECT_NAME} ${COMMONS_UTILS_SOURCE_FILES})
target_link_libraries(${PROJECT_NAME} ${ZMQ_LINK_LIBRARIES})
