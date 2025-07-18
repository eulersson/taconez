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

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include <cjson/cJSON.h>
#include <pulse/error.h>
#include <pulse/simple.h>
#include <zmq.h>

#include <taconez/commons/socket.h>

#include "process_loop.h"

/**
 * Entry point for the sound player. Waits for messages from the distributor and plays
 * the sounds it receives.
 */
int main(void)
{
  void *context = zmq_ctx_new();
  void *sub_socket = zmq_socket(context, ZMQ_SUB);

  char *playback_distributor_host = getenv("PLAYBACK_DISTRIBUTOR_HOST");
  if (playback_distributor_host == NULL)
  {
    playback_distributor_host = "playback-distributor";
  }

  char playback_distributor_address[100];
  sprintf(playback_distributor_address, "tcp://%s:5556", playback_distributor_host);

  printf("[player] Connecting to distributor at %s...\n", playback_distributor_address);

  zmq_connect(sub_socket, playback_distributor_address);

  // Subscribe to all messages.
  zmq_setsockopt(sub_socket, ZMQ_SUBSCRIBE, "", 0);

  printf("[player] Ready!\n");

  while (1)
  {
    int finished = process_loop(sub_socket);
    if (finished)
    {
      break;
    }
  }

  printf("[player] Bye!\n");

  // TODO: Fix the hanging of zmq_close https://github.com/eulersson/taconez/issues/94
  zmq_close(sub_socket);
  zmq_ctx_destroy(context);

  return 0;
}
