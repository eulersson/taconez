#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <anesowa/commons/utils.h>

#include "message.h"

int process_loop(void *pull_socket, void *pub_socket) {
  char *message = s_recv(pull_socket);
  printf("[distributor] Received: %s\n", message);

  struct ParsedMessage pm = parse_message(message);
  printf("[distributor] When: %s | Sound file: %s (absolute path %s)\n",
         pm.when, pm.sound_file, pm.abs_sound_file_path);

  char processed_message[256]; // Make sure the array is large enough to hold
                               // the string
  strcpy(processed_message, message);
  printf("[distributor] Publishing: %s\n", processed_message);
  s_send(pub_socket, processed_message);

  int finished = strcmp(message, "exit") == 0;
  free(message);

  return finished;
}
