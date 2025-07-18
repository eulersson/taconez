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

#include <time.h>

#include <unity.h>

#include "process_loop.h"
#include "time_utils.h"

#include "fff.h"

DEFINE_FFF_GLOBALS;

FAKE_VALUE_FUNC(int, play_sound, char *)
FAKE_VALUE_FUNC(char *, s_recv, void *)

#define FFF_FAKES_LIST(FAKE)                                                   \
  FAKE(play_sound)                                                             \
  FAKE(s_recv)

void setUp(void) {
  FFF_FAKES_LIST(RESET_FAKE);
  FFF_RESET_HISTORY();
}

void get_current_time(char *buffer, size_t buffer_size) {
  time_t rawtime;
  time(&rawtime);

  struct tm *tm = gmtime(&rawtime);

  strftime(buffer, buffer_size, "%Y-%m-%dT%H:%M:%S", tm);
}

void tearDown(void) {}

/**
 * Given a message received from the Playback Distributor instructing to play a
 * sound When the timestamp of that message is way in the past Then we don't
 * play that sound since it's expired, too old!
 */
void test_not_playing_old_sound(void) {
  char receives[512];

  long now = get_now();
  long forty_seconds_ago = now - 40;

  sprintf(
      receives,
      "{ \"when\": %ld, "
      "\"sound_file_path\": \"a_file_name.wav\","
      "\"abs_sound_file_path\": \"/full/path/to/a_file_name.wav\","
      "\"preroll_file\": \"another_file_name.wav\","
      "\"abs_preroll_file_path\": \"/path/to/prerolls/another_file_name.wav\","
      "\"preroll_file_path\": \"another_file_name.wav\","
      "\"sound_duration\": \"10\","
      "\"preroll_duration\": \"8.34\" }",
      forty_seconds_ago);

  // This gets freed in process_loop.c.
  char *mocked_msg = strdup(receives);

  // Get the size in bytes of mocked_msg.
  int mocked_msg_size = strlen(mocked_msg) + 1;

  s_recv_fake.return_val = mocked_msg;

  int finish = process_loop(NULL);

  TEST_ASSERT_EQUAL(0, play_sound_fake.call_count);
}

/**
 * Given a Playback Distributor
 * When it receives an "exit" message instead of a JSON
 * Then it must stop listening, pass the message to players and honour it by
 * exiting.
 */
void test_exits_when_receiving_exit_string(void) {
  char *receives = "exit";

  // This gets freed in process_loop.c.
  char *mocked_msg = strdup(receives);

  s_recv_fake.return_val = mocked_msg;

  int finish = process_loop(NULL);

  TEST_ASSERT_EQUAL(1, finish);
  TEST_ASSERT_EQUAL(1, s_recv_fake.call_count);
}
