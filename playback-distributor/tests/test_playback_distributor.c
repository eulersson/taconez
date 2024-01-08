#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <unity.h>

#include <anesowa/commons/message.h>

#include "process_loop.h"

#include "fff.h"

DEFINE_FFF_GLOBALS;

FAKE_VALUE_FUNC(char *, s_recv, void *)
FAKE_VALUE_FUNC(int, s_send, void *, char *)

#define FFF_FAKES_LIST(FAKE)                                                   \
  FAKE(s_recv)                                                                 \
  FAKE(s_send)

void setUp(void) {
  FFF_FAKES_LIST(RESET_FAKE);
  FFF_RESET_HISTORY();
}

void tearDown(void) {}

/**
 * Given a detected sound that has been identified by Sound Detectors
 * When the Playback Distributor is notified
 * Then it propagates the instruction to playback the sound to all Sound
 * Players.
 */
void test_message_is_propagated_to_players(void) {
  char *receives = "{ \"when\": \"2024-01-07T17:02:47.679046+00:00\", "
                   "\"sound_file\": \"a_file_name.wav\" }";
  char *sends = "{ \"when\": \"2024-01-07T17:02:47.679046+00:00\", "
                "\"sound_file\": \"a_file_name.wav\" }";

  // This gets freed in process_loop.c.
  char *mocked_msg = strdup(receives);

  // Get the size in bytes of mocked_msg.
  int mocked_msg_size = strlen(mocked_msg) + 1;

  s_recv_fake.return_val = mocked_msg;
  s_send_fake.return_val = mocked_msg_size;

  int finish = process_loop(NULL, NULL);

  TEST_ASSERT_EQUAL(finish, 0);
  TEST_ASSERT_EQUAL(s_recv_fake.call_count, 1);
  TEST_ASSERT_EQUAL_STRING(receives, s_send_fake.arg1_val);
}

/**
 * Given a Playback Distributor
 * When it receives an "exit" message instead of a JSON
 * Then it must stop listening, pass the message to players and honour it by
 * exiting.
 */
void test_exits_when_receiving_exit_string(void) {
  char *receives = "exit";
  char *sends = "exit";

  // This gets freed in process_loop.c.
  char *mocked_msg = strdup(receives);

  // Get the size in bytes of mocked_msg.
  int mocked_msg_size = strlen(mocked_msg) + 1;

  s_recv_fake.return_val = mocked_msg;
  s_send_fake.return_val = mocked_msg_size;

  int finish = process_loop(NULL, NULL);

  TEST_ASSERT_EQUAL(finish, 1);
  TEST_ASSERT_EQUAL(s_recv_fake.call_count, 1);
  TEST_ASSERT_EQUAL_STRING(receives, s_send_fake.arg1_val);
}
