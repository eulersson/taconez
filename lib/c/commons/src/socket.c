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

#include <string.h>
#include <zmq.h>

int s_send(void *socket, char *string) {
  int size = zmq_send(socket, string, strlen(string), 0);
  return size;
}

// Receive ZeroMQ string from socket and convert into C string. Caller must free
// returned string. Returns NULL if the context is being terminated.
char *s_recv(void *socket) {
  enum { cap = 1024 };

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
