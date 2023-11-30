#include <stdio.h>
#include <stdlib.h>

#include <zmq.h>

#include "utils.h"

int main(void) {
  void *context = zmq_ctx_new();
  void *sub_socket = zmq_socket(context, ZMQ_SUB);
  zmq_connect(sub_socket, "tcp://localhost:5556");
  zmq_setsockopt(sub_socket, ZMQ_SUBSCRIBE, "", 0);

  printf("[player] Ready!\n");

  while (1) {
    char *message = s_recv(sub_socket);
    printf("[player] Received: %s\n", message);

    int finished = strcmp(message, "exit") == 0;
    free(message);
    if (finished) {
      break;
    }
  }

  printf("[player] Bye!\n");
  zmq_close(sub_socket);
  zmq_ctx_destroy(context);
  return 0;
}
