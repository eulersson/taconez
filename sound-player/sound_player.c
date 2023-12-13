#include <stdio.h>
#include <stdlib.h>

#include <zmq.h>

#include "utils.h"

int main(void) {
  void *context = zmq_ctx_new();

  void *pull_socket = zmq_socket(context, ZMQ_PULL);
  zmq_bind(pull_socket, "tcp://*:5555");

  void *pub_socket = zmq_socket(context, ZMQ_PUB);
  zmq_bind(pub_socket, "tcp://*:5556");

  printf("[distributor] Broker (PULL and PUB sockets) ready!\n");

  while (1) {
    char *message = s_recv(pull_socket);
    printf("[distributor] Received: %s\n", message);

    printf("[distributor] Publishing: %s\n", message);
    s_send(pub_socket, message);

    int finished = strcmp(message, "exit") == 0;
    free(message);
    if (finished) {
      break;
    }
  }

  printf("[distributor] Bye!\n");
  zmq_close(pull_socket);
  zmq_ctx_destroy(context);
  return 0;
}
