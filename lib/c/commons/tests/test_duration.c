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
    // This test can get run by executables built by taconez/lib/c/commons/CMakelists.txt
    // or by taconez/playback-distributor/CMakelists.txt or by
    // taconez/sound-player/CMakelists.txt, depending on the case the sample to find
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
    
    // Intended to be run from taconez/playback-distributor or taconez/sound-player.
    float duration = get_duration(sample_path);
    printf("Duration: %f\n", duration);
    TEST_ASSERT_EQUAL(30.00, duration);
}
