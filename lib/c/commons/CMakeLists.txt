cmake_minimum_required(VERSION 3.10)

project(anesowa_commons)

# Produces the JSON Compilation Database (`compile_comands.json`) used by clangd (the 
# C++ language server) so it works with Neovim's language server feature:
#
#   https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#clangd
#
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(CMakePrintHelpers)

include_directories(./include)

# Add third-party libraries and include paths.
find_path(ZMQ_INCLUDE_DIR zmq.h)
cmake_print_variables(ZMQ_INCLUDE_DIR)
include_directories(${ZMQ_INCLUDE_DIR})

# Create the library.
add_library(commons_utils src/utils.c)
