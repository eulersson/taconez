#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <anesowa/commons/duration.h>
#include <anesowa/commons/message.h>
#include <anesowa/commons/socket.h>

#include "play.h"
#include "time_utils.h"

int process_loop(void *sub_socket) {
  char *message = s_recv(sub_socket);
  printf("[player] Received: %s\n", message);

  int finished = strcmp(message, "exit") == 0;
  if (finished) {
    printf("[distributor] Received orders to shut down (message: %s)\n",
           message);
  } else {
    struct ParsedMessage pm = parse_message(message);
    printf("[distributor] When: %s | Sound file: %s (absolute path %s)\n",
           pm.when, pm.sound_file, pm.abs_sound_file_path);

    int detected_sound_duration = get_duration(pm.abs_sound_file_path);
    int preroll_sound_duration = get_duration(pm.abs_preroll_file_path);
    int duration_playing = detected_sound_duration + preroll_sound_duration;

    time_t when = parse_time(pm.when);
    time_t now = get_now();

    // Make sure it's not too late to play the sound.
    if(difftime(now - duration_playing, when) < 10) {
      printf("[distributor] In time to play the sound. Playing.\n")
    } else{
      printf("[distributor] It's too late to play the sound. Skipping.\n");

      // TODO: Play pre-roll.
      play_sound(abs_preroll_file_path);

      // TODO: Synchronize it so the sound is played after the preroll.
      play_sound(abs_sound_file_path);
      free(pm.abs_sound_file_path);
    }
    free(message);
  }


  return finished;
}
