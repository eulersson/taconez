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

find_library(PULSEAUDIO_SIMPLE_LIBRARY pulse-simple)
cmake_print_variables(PULSEAUDIO_SIMPLE_LIBRARY)

find_library(ZMQ_LIBRARY zmq)
cmake_print_variables(ZMQ_LIBRARY)

include_directories(${PULSEAUDIO_INCLUDE_DIR})

set(SOUND_PLAYER_SOURCE_FILES sound_player.c)
set(TEST_PLAY_SOURCE_FILES test_play.c)

add_executable(sound_player ${SOUND_PLAYER_SOURCE_FILES})
add_executable(test_play ${TEST_PLAY_SOURCE_FILES})

target_link_libraries(test_play ${PULSEAUDIO_LIBRARY})
target_link_libraries(test_play ${PULSEAUDIO_SIMPLE_LIBRARY})

target_link_libraries(sound_player ${PULSEAUDIO_LIBRARY})
target_link_libraries(sound_player ${PULSEAUDIO_SIMPLE_LIBRARY})
target_link_libraries(sound_player ${ZMQ_LIBRARY})
