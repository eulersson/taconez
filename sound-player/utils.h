// ====================================================================================
// utils.h
//
// Helpers and utils for the application.
//
// Source:
//
//   - https://github.com/booksbyus/zguide/blob/master/examples/C/zhelpers.h
//
// ====================================================================================
#include <string.h>
#include <zmq.h>

static int s_send(void *socket, char *string) {
  int size = zmq_send(socket, string, strlen(string), 0);
  return size;
}

// Receive ZeroMQ string from socket and convert into C string. Caller must free
// returned string. Returns NULL if the context is being terminated.
static char *s_recv(void *socket) {
  enum { cap = 256 };

  char buffer[cap];

  int size = zmq_recv(socket, buffer, cap - 1, 0);

  if (size == -1)
    return NULL;

  buffer[size < cap ? size : cap - 1] = '\0';

#if (defined(WIN32))
  return strdup(buffer);
#else
  return strndup(buffer, sizeof(buffer) - 1);
#endif

  // Remember that the strdup family of functions use malloc/alloc for space for
  // the new string. It must be manually freed when you are done with it.
  // Failure to do so will allow a heap attack.
}
