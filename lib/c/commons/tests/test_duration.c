#include <unity.h>

#include "duration.h"

void setUp(void) {}

void tearDown(void) {}

/**
 * Given a .wav file
 * When the duration analizer runs
 * Then it returns the duration of the audio in seconds
 */
void test_duration(void) { 
    // Intended to be run from anesowa/playback-distributor or anesowa/sound-player.
    float duration = get_duration("../../../prerolls/sample.wav");
    printf("Duration: %f\n", duration);
    TEST_ASSERT_EQUAL(duration, 30.00);
}
