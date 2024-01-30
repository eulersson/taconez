#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <unity.h>

#include "preroll.h"

#include "fff.h"

DEFINE_FFF_GLOBALS;

FAKE_VALUE_FUNC(char *, s_recv, void *);
FAKE_VALUE_FUNC(int, s_send, void *, char *);
FAKE_VALUE_FUNC(float, get_duration, char *);

FAKE_VALUE_FUNC(int, rand);

#define FFF_FAKES_LIST(FAKE) \
    FAKE(s_recv)             \
    FAKE(s_send)             \
    FAKE(get_duration)       \
    FAKE(rand)

void setUp(void)
{
    FFF_FAKES_LIST(RESET_FAKE);
    FFF_RESET_HISTORY();
}

void tearDown(void) {}

/**
 * Given a Playback Distributor
 * When it has to randomly select a preroll file
 * Then it must choose one of the files in the prerolls directory.
 */
void test_randomly_choose_preroll_file()
{
    // Set up rand fake, that would be "preroll_3.wav", because "." and ".." will be skipped.
    rand_fake.return_val = 2;

    // Call function under test
    char *result = randomly_choose_preroll_file();

    // Verify result
    TEST_ASSERT_EQUAL_STRING("preroll_3.wav", result);

    // Clean up
    // free(result);
}