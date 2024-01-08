#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <anesowa/commons/socket.h>
#include <anesowa/commons/message.h>

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
    printf("[distributor] When: %s | Sound file: %s (absolute path %s)\n",
           pm.when, pm.sound_file, pm.abs_sound_file_path);

    printf("[distributor] Publishing: %s\n", processed_message);
    s_send(pub_socket, processed_message);
  }
  free(message);

  return finished;
}
