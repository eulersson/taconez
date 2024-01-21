// ====================================================================================
// Sound Player Module (sound_player.c)
//
// Listens to the distributor to receive sound files to play.
// ====================================================================================

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
// #include <sys/fcntl.h>
#include <time.h>
#include <unistd.h>

#include <cjson/cJSON.h>
#include <pulse/error.h>
#include <pulse/simple.h>
#include <zmq.h>

#include <anesowa/commons/socket.h>

#include "process_loop.h"

int main(void) {
  void *context = zmq_ctx_new();
  void *sub_socket = zmq_socket(context, ZMQ_SUB);

  // TODO: Read from environment variable or pass as CLI argument.
  zmq_connect(sub_socket, "tcp://playback-distributor:5556");

  zmq_setsockopt(sub_socket, ZMQ_SUBSCRIBE, "", 0);

  printf("[player] Ready!\n");

  while (1) {
    int finished = process_loop(sub_socket);
    if (finished) {
      break;
    }
  }

  printf("[player] Bye!\n");
  zmq_close(sub_socket);
  zmq_ctx_destroy(context);
  return 0;
}
