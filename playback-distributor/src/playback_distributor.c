#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <cjson/cJSON.h>
#include <zmq.h>

#include "message.h"
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
  zmq_close(pull_socket);
  zmq_ctx_destroy(context);
  return 0;
}
