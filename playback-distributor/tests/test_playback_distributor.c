#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <unity.h>

#include "message.h"
#include "process_loop.h"

#include "fff.h"

DEFINE_FFF_GLOBALS;
FAKE_VALUE_FUNC(char *, s_recv, void *);
FAKE_VALUE_FUNC(int, s_send, void *, char *);

void setUp(void) {}

void tearDown(void) {}

void test_message_is_propagated_to_players(void) {
  // This gets freed in process_loop.c.
  char *receives = "{ \"when\": \"2024-01-07T17:02:47.679046+00:00\", "
                   "\"sound_file\": \"a_file_name.wav\" }";
  char *sends = "{ \"when\": \"2024-01-07T17:02:47.679046+00:00\", "
                "\"sound_file\": \"a_file_name.wav\" }";
  char *mocked_msg = strdup(receives);

  // Get the size in bytes of mocked_msg.
  int mocked_msg_size = strlen(mocked_msg) + 1;

  s_recv_fake.return_val = mocked_msg;
  s_send_fake.return_val = mocked_msg_size;

  process_loop(NULL, NULL);

  TEST_ASSERT_EQUAL(s_recv_fake.call_count, 1);
  TEST_ASSERT_EQUAL_STRING(receives, s_send_fake.arg1_val);
}

void test_parse_message(void) { TEST_ASSERT_EQUAL(1, 2); }

void test_exits_when_receiving_exit_string(void) { TEST_ASSERT_EQUAL(1, 2); }
