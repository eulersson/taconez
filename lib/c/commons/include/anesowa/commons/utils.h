// ====================================================================================
// Utils & Helpers (utils.h)
//
// Helpers and utils for the application.
//
// Source:
//
//   - https://github.com/booksbyus/zguide/blob/master/examples/C/zhelpers.h
//
// ====================================================================================
int s_send(void *socket, char *string);

// Receive ZeroMQ string from socket and convert into C string. Caller must free
// returned string. Returns NULL if the context is being terminated.
char *s_recv(void *socket);
