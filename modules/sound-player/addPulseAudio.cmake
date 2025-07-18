# Third party: PulseAudio (Core API).
find_package(PulseAudio)

cmake_print_variables(PULSEAUDIO_INCLUDE_DIR)
cmake_print_variables(PULSEAUDIO_LIBRARY)

# # Third party: PulseAudio (Simple API).
find_library(PULSEAUDIO_SIMPLE_LIBRARY pulse-simple)
cmake_print_variables(PULSEAUDIO_SIMPLE_LIBRARY)

# Prepare the sources to include in the target.
list(APPEND DIRS_TO_INCLUDE ${PULSEAUDIO_INCLUDE_DIR})
list(APPEND LIBS_TO_LINK ${PULSEAUDIO_LIBRARY} ${PULSEAUDIO_SIMPLE_LIBRARY})
