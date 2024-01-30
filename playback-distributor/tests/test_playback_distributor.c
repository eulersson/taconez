#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <unity.h>

#include <taconez/commons/message.h>

#include "preroll.h"
#include "process_loop.h"

#include "fff.h"

DEFINE_FFF_GLOBALS;

FAKE_VALUE_FUNC(char *, s_recv, void *);
FAKE_VALUE_FUNC(int, s_send, void *, char *);
FAKE_VALUE_FUNC(float, get_duration, char *);
FAKE_VALUE_FUNC(int, rand);

#define FFF_FAKES_LIST(FAKE) \
  FAKE(s_recv)               \
  FAKE(s_send)               \
  FAKE(get_duration)         \
  FAKE(rand)

void setUp(void)
{
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
void test_message_is_propagated_to_players(void)
{
  float get_duration_return_vals[2] = {6.1, 10.2};
  SET_RETURN_SEQ(get_duration, get_duration_return_vals, 2);

  char *receives = "{ \"when\": 1704719500, "
                   "\"sound_file_path\": \"a_file_name.wav\" }";

char *sends = "{\"when\":1704719500,"
    "\"sound_file_path\":\"a_file_name.wav\","
    "\"abs_sound_file_path\":\"/app/recordings/a_file_name.wav\","
    "\"preroll_file_path\":\"preroll_1.wav\","
    "\"abs_preroll_file_path\":\"/app/prerolls/preroll_1.wav\","
    "\"sound_duration\":6.0999999046325684,"
    "\"preroll_duration\":10.199999809265137}";

  char *mocked_msg = strdup(receives);

  // Get the size in bytes of mocked_msg.
  int mocked_msg_size = strlen(mocked_msg) + 1;

  s_recv_fake.return_val = mocked_msg;
  s_send_fake.return_val = mocked_msg_size;

  int finish = process_loop(NULL, NULL);

  TEST_ASSERT_EQUAL(0, finish);
  TEST_ASSERT_EQUAL(2, get_duration_fake.call_count);
  TEST_ASSERT_EQUAL(1, s_recv_fake.call_count);
  TEST_ASSERT_EQUAL_STRING(sends, s_send_fake.arg1_val);
}

/**
 * Given a Playback Distributor
 * When it receives an "exit" message instead of a JSON
 * Then it must stop listening, pass the message to players and honour it by
 * exiting.
 */
void test_exits_when_receiving_exit_string(void)
{
  char *receives = "exit";
  char *sends = "exit";

  // This gets freed in process_loop.c.
  char *mocked_msg = strdup(receives);

  // Get the size in bytes of mocked_msg.
  int mocked_msg_size = strlen(mocked_msg) + 1;

  s_recv_fake.return_val = mocked_msg;
  s_send_fake.return_val = mocked_msg_size;

  int finish = process_loop(NULL, NULL);

  TEST_ASSERT_EQUAL(1, finish);
  TEST_ASSERT_EQUAL(1, s_recv_fake.call_count);
  TEST_ASSERT_EQUAL_STRING(receives, s_send_fake.arg1_val);
}
