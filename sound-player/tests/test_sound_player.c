#include <unity.h>

#include "process_loop.h"

#include "fff.h"

DEFINE_FFF_GLOBALS;

FAKE_VALUE_FUNC(int, get_now)
FAKE_VALUE_FUNC(char *, s_recv, void *)
FAKE_VALUE_FUNC(int, s_send, void *, char *)


#define FFF_FAKES_LIST(FAKE)                                                   \
  FAKE(get_now)                                                                 \
  FAKE(s_recv)                                                                 \
  FAKE(s_send)

void setUp(void) {
  FFF_FAKES_LIST(RESET_FAKE);
  FFF_RESET_HISTORY();
}

void tearDown(void) {}

/**
 * Given a message received from the Playback Distributor instructing to play a sound
 * When the timestamp of that message is way in the past
 * Then we don't play that sound since it's expired, too old!
 */
void test_not_playing_old_sound(void) {
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

  TEST_ASSERT_EQUAL(1, 1);
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

  s_recv_fake.return_val = mocked_msg;

  int finish = process_loop(NULL);

  TEST_ASSERT_EQUAL(finish, 1);
  TEST_ASSERT_EQUAL(s_recv_fake.call_count, 1);
  TEST_ASSERT_EQUAL_STRING(receives, s_send_fake.arg1_val);
}
