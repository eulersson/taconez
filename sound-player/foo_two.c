#include <stdio.h>

#include <zmq.h>

#include <anesowa_commons/utils.h>

int main(void) {
  void *context = zmq_ctx_new();
  void *push_socket = zmq_socket(context, ZMQ_PUSH);
  zmq_connect(push_socket, "tcp://localhost:5555");

  printf("[detector] Ready!\n");

  char buffer[256];
  while (1) {
    printf("[detector] Type message to send: ");
    scanf("%s", buffer);
    printf("[detector] Sending: %s\n", buffer);
    s_send(push_socket, buffer);
    if (strcmp(buffer, "exit") == 0) {
      break;
    }
  }

  printf("[detector] Bye!");
  zmq_close(push_socket);
  zmq_ctx_destroy(context);
  return 0;
}
