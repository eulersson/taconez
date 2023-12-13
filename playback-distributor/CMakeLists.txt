cmake_minimum_required(VERSION 3.10)

project(playback_distributor)

include(CMakePrintHelpers)

# Produces the JSON Compilation Database (`compile_comands.json`) used by clangd (the 
# C++ language server) so it works with Neovim's language server feature:
#
#   https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#clangd
#
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Add anesowa common library and include paths.
add_subdirectory(../lib/c/commons anesowa_commons)
cmake_print_variables(CMAKE_CURRENT_SOURCE_DIR)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../lib/c/commons/include)

# Add third-party libraries and include paths.
find_path(ZMQ_INCLUDE_DIR zmq.h)
cmake_print_variables(ZMQ_INCLUDE_DIR)
include_directories(${ZMQ_INCLUDE_DIR})

find_library(ZMQ_LIBRARY zmq)
cmake_print_variables(ZMQ_LIBRARY)

# Link our executable to the libraries it needs.
add_executable(playback_distributor playback_distributor.c)
target_link_libraries(playback_distributor ${ZMQ_LIBRARY})
target_link_libraries(playback_distributor anesowa_commons)
