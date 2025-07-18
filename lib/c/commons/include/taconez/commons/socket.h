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

// =====================================================================================
// ZeroMQ Socket-Related Helpers (socket.h)
//
// Source:
//
//   - https://github.com/booksbyus/zguide/blob/master/examples/C/zhelpers.h
//
// =====================================================================================

#ifndef SOCKET_H
#define SOCKET_H

// Send a string to the ZMQ socket.
int s_send(void *socket, char *string);

// Receive ZeroMQ string from socket and convert into C string. Caller must free
// returned string. Returns NULL if the context is being terminated.
char *s_recv(void *socket);

#endif
