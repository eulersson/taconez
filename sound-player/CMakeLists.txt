cmake_minimum_required(VERSION 3.10)

project(sound-player)

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
find_path(PULSEAUDIO_INCLUDE_DIR pulse/pulseaudio.h)
cmake_print_variables(PULSEAUDIO_INCLUDE_DIR)
include_directories(${PULSEAUDIO_INCLUDE_DIR})

find_library(PULSEAUDIO_LIBRARY pulse)
cmake_print_variables(PULSEAUDIO_LIBRARY)

find_library(PULSEAUDIO_SIMPLE_LIBRARY pulse-simple)
cmake_print_variables(PULSEAUDIO_SIMPLE_LIBRARY)

find_path(ZMQ_INCLUDE_DIR zmq.h)
cmake_print_variables(ZMQ_INCLUDE_DIR)
include_directories(${ZMQ_INCLUDE_DIR})

find_library(ZMQ_LIBRARY zmq)
cmake_print_variables(ZMQ_LIBRARY)

# Prepare the sources to include in the library.
set(SOUND_PLAYER_SOURCE_FILES sound_player.c)

add_executable(sound-player ${SOUND_PLAYER_SOURCE_FILES})

target_link_libraries(sound-player anesowa_commons)
target_link_libraries(sound-player ${PULSEAUDIO_LIBRARY})
target_link_libraries(sound-player ${PULSEAUDIO_SIMPLE_LIBRARY})
target_link_libraries(sound-player ${ZMQ_LIBRARY})
