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

#include <cjson/cJSON.h>
#include <zmq.h>

#include <taconez/commons/message.h>
#include <taconez/commons/socket.h>

#include "process_loop.h"

int main(void) {
  void *context = zmq_ctx_new();

  void *pull_socket = zmq_socket(context, ZMQ_PULL);
  zmq_bind(pull_socket, "tcp://*:5555");

  void *pub_socket = zmq_socket(context, ZMQ_PUB);
  zmq_bind(pub_socket, "tcp://*:5556");

  printf("[distributor] Broker (PULL and PUB sockets) ready!\n");

  while (1) {
    int finished = process_loop(pull_socket, pub_socket);
    if (finished) {
      break;
    }
  }

  printf("[distributor] Bye!\n");

  // TODO: Fix the hanging of zmq_close https://github.com/eulersson/taconez/issues/94
  zmq_close(pull_socket);
  zmq_ctx_destroy(context);
  return 0;
}
