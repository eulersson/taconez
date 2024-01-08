#include <unistd.h>

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
    // This test can get run by executables built by anesowa/lib/c/commons/CMakelists.txt
    // or by anesowa/playback-distributor/CMakelists.txt or by
    // anesowa/sound-player/CMakelists.txt, depending on the case the sample to find
    // might be in a different relative path.
    char *sample_path1 = "../../../prerolls/sample.wav";
    char *sample_path2 = "../../../../prerolls/sample.wav";
    char *sample_path;

    if (access(sample_path1, F_OK) != -1) {
        // File exists
        sample_path = sample_path1;
    } else if (access(sample_path2, F_OK) != -1) {
        // File exists
        sample_path = sample_path2;
    } else {
        // File doesn't exist
        printf("File does not exist\n");
        return;
    }
    
    // Intended to be run from anesowa/playback-distributor or anesowa/sound-player.
    float duration = get_duration(sample_path);
    printf("Duration: %f\n", duration);
    TEST_ASSERT_EQUAL(30.00, duration);
}
