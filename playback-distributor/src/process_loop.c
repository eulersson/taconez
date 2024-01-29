#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <taconez/commons/duration.h>
#include <taconez/commons/message.h>
#include <taconez/commons/socket.h>

int process_loop(void *pull_socket, void *pub_socket) {
  char *message_in_str = s_recv(pull_socket);

  // This helps us do assertions on s_send in the tests, since otherwise the string
  // would be freed and would not be able to check the arguments of the s_send mocked
  // function.
  char processed_message_in[256];
  strcpy(processed_message_in, message_in_str);

  printf("[distributor] Received: %s\n", message_in_str);

  int finished = strcmp(message_in_str, "exit") == 0;
  if (finished) {
    printf("[distributor] Telling other players to exit (message_in_str: %s)\n",
           message_in_str);
    s_send(pub_socket, processed_message_in);
  } else {
    struct DetectorMessage msg_in = parse_detector_message(message_in_str);
    printf("[distributor] When: %ld | Sound file: %s (absolute path %s)\n",
           msg_in.when, msg_in.sound_file_path, msg_in.abs_sound_file_path);

    // TODO: Instead of hardcoding the prerolls, we should read them from the folder.
    // https://github.com/eulersson/taconez/issues/33
    char* prerolls[3];
    prerolls[0] = "preroll_1.wav";
    prerolls[1] = "preroll_2.wav";
    prerolls[2] = "preroll_3.wav";

    int chosen_preroll_index = rand() % 2;
    char* preroll_file_path = prerolls[chosen_preroll_index];
    printf("[distributor] Preroll file path: %s\n", preroll_file_path);

    int bytes_to_alloc = strlen("/app/prerolls/") + strlen(preroll_file_path) + 1;
    char *abs_preroll_file_path = malloc(bytes_to_alloc);
    strcpy(abs_preroll_file_path, "/app/prerolls/");
    strcat(abs_preroll_file_path, preroll_file_path);

    float sound_duration = get_duration(msg_in.abs_sound_file_path);
    printf("[distributor] Sound duration: %f\n", sound_duration);
    float preroll_duration = get_duration(abs_preroll_file_path);
    printf("[distributor] Preroll duration: %f\n", preroll_duration);

    struct DistributorMessage msg_out = {
      msg_in.when,
      msg_in.sound_file_path,
      msg_in.abs_sound_file_path,
      preroll_file_path,
      abs_preroll_file_path,
      sound_duration,
      preroll_duration
    };

    char *msg_out_str = write_distributor_message(&msg_out);

    printf("[distributor] Publishing: %s\n", msg_out_str);
    s_send(pub_socket, msg_out_str);

    free(msg_in.abs_sound_file_path);
    free(abs_preroll_file_path);
    free(msg_out_str);
  }

  free(message_in_str);

  return finished;
}
