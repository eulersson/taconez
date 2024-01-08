#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <anesowa/commons/duration.h>
#include <anesowa/commons/message.h>
#include <anesowa/commons/socket.h>

int process_loop(void *pull_socket, void *pub_socket) {
  char *message = s_recv(pull_socket);

  // This helps us do assertions on s_send in the tests, since otherwise the string
  // would be freed and would not be able to check the arguments of the s_send mocked
  // function.
  char processed_message[256];
  strcpy(processed_message, message);

  printf("[distributor] Received: %s\n", message);

  int finished = strcmp(message, "exit") == 0;
  if (finished) {
    printf("[distributor] Telling other players to exit (message: %s)\n",
           message);
    s_send(pub_socket, processed_message);
  } else {
    struct DetectorMessage pm = parse_detector_message(message);
    printf("[distributor] When: %ld | Sound file: %s (absolute path %s)\n",
           pm.when, pm.sound_file_path, pm.abs_sound_file_path);

    // TODO: Instead of hardcoding the prerolls, we should read them from the folder.
    char* prerolls[2];
    prerolls[0] = "posa-t-sabatilles.wav";
    prerolls[1] = "vale-ja-amb-els-tacons.wav";

    int chosen_preroll_index = rand() % 2;
    char* preroll_file_path = prerolls[chosen_preroll_index];

    char *abs_preroll_file_path = malloc(
      strlen("/anesowa/prerolls/") + strlen(preroll_file_path) + 1
    );
    strcpy(abs_preroll_file_path, "/anesowa/prerolls/");
    strcat(abs_preroll_file_path, preroll_file_path);

    float sound_duration = get_duration(pm.abs_sound_file_path);
    printf("[distributor] Sound duration: %f\n", sound_duration);
    float preroll_duration = get_duration(abs_preroll_file_path);
    printf("[distributor] Preroll duration: %f\n", preroll_duration);

    struct DistributorMessage dm = {
      pm.when,
      pm.sound_file_path,
      pm.abs_sound_file_path,
      preroll_file_path,
      abs_preroll_file_path,
      sound_duration,
      preroll_duration
    };

    printf("[distributor] Publishing: %s\n", processed_message);
    s_send(pub_socket, processed_message);
  }
  free(message);

  return finished;
}
