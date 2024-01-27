#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <taconez/commons/duration.h>
#include <taconez/commons/message.h>
#include <taconez/commons/socket.h>

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
    struct DistributorMessage pm = parse_distributor_message(message);
    printf("[distributor] When: %ld | "
           "Sound file: %s (absolute path %s) | "
           "Preroll file: %s (absolute path %s) | "
           "Sound duration: %f |"
           "Prefix duration: %f\n",
           pm.when, pm.sound_file_path, pm.abs_sound_file_path,
           pm.preroll_file_path, pm.abs_preroll_file_path, pm.sound_duration,
           pm.preroll_duration);

    float duration_playing = pm.sound_duration + pm.preroll_duration;

    time_t now = get_now();

    printf("when: %ld\n", pm.when);
    printf("now: %ld\n", now);

    // Make sure it's not too late to play the sound.
    long time_delta = difftime(now, pm.when);
    printf("[distributor] Time delta: %ld\n", time_delta);
    // TODO: Make the 10 seconds a configuration parameter.
    if (time_delta < 10) {
      printf("[distributor] In time to play the sound. Honouring the play of %s.\n", pm.abs_sound_file_path);

      // TODO: Play pre-roll before the sound... After the preroll is finished it should
      // play the following sound afterwards.
      // // play_sound(pm.abs_preroll_file_path);

      // TODO: Synchronize it so the sound is played after the preroll.
      play_sound(pm.abs_sound_file_path);
    } else {
      printf(
        "[distributor] It's too late to play the sound (%ld seconds ago). Skipping.\n",
        time_delta
      );
    }

    // Free the dynamically allocated string (see message.c).
    free(pm.abs_preroll_file_path);

    // Free the dynamically allocated string created by ZeroMQ.
    free(message);
  }

  return finished;
}
