// Copyright 2024 Ramon Blanquer Ruiz
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <taconez/commons/duration.h>
#include <taconez/commons/message.h>
#include <taconez/commons/socket.h>

#include "preroll.h"

int process_loop(void *pull_socket, void *pub_socket)
{
  char *message_in_str = s_recv(pull_socket);

  // This helps us do assertions on s_send in the tests, since otherwise the string
  // would be freed and would not be able to check the arguments of the s_send mocked
  // function.
  char processed_message_in[256];
  strcpy(processed_message_in, message_in_str);

  printf("[distributor] Received: %s\n", message_in_str);

  int finished = strcmp(message_in_str, "exit") == 0;
  if (finished)
  {
    printf("[distributor] Telling other players to exit (message_in_str: %s)\n",
           message_in_str);
    s_send(pub_socket, processed_message_in);
  }
  else
  {
    struct DetectorMessage msg_in = parse_detector_message(message_in_str);
    printf("[distributor] When: %ld | Sound file: %s (absolute path %s)\n",
           msg_in.when, msg_in.sound_file_path, msg_in.abs_sound_file_path);

    // Look into the /app/prerolls folder and choose a random preroll.
    char *preroll_file_path = randomly_choose_preroll_file();

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
        preroll_duration};

    char *msg_out_str = write_distributor_message(&msg_out);

    printf("[distributor] Publishing: %s\n", msg_out_str);
    s_send(pub_socket, msg_out_str);

    free(preroll_file_path);
    free(msg_in.abs_sound_file_path);
    free(abs_preroll_file_path);
    free(msg_out_str);
  }

  free(message_in_str);

  return finished;
}
