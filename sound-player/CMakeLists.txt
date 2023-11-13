cmake_minimum_required(VERSION 3.10)

project(sound_player)

# Produces the JSON Compilation Database (`compile_comands.json`) used by clangd (the 
# C++ language server) so it works with Neovim's language server feature:
#
#   https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#clangd
#
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(CMakePrintHelpers)

find_path(PULSEAUDIO_INCLUDE_DIR pulse/pulseaudio.h)
cmake_print_variables(PULSEAUDIO_INCLUDE_DIR)

find_library(PULSEAUDIO_LIBRARY pulse)
cmake_print_variables(PULSEAUDIO_LIBRARY)

find_library(ZMQ_LIBRARY zmq)
cmake_print_variables(ZMQ_LIBRARY)

include_directories(${PULSEAUDIO_INCLUDE_DIRS})

set(SOURCE_FILES sound_player.c)

add_executable(sound_player ${SOURCE_FILES})

target_link_libraries(sound_player pulse-simple pulse)
target_link_libraries(sound_player ${ZMQ_LIBRARY})
