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

#include <stdio.h>
#include <stdlib.h>

typedef struct {
  char chunkId[4];
  int chunkSize;
  char format[4];
  char subchunk1Id[4];
  int subchunk1Size;
  short audioFormat;
  short numChannels;
  int sampleRate;
  int byteRate;
  short blockAlign;
  short bitsPerSample;
} WavHeader;

float get_duration(char *wav_absolute_file_path) {
  FILE *file = fopen(wav_absolute_file_path, "rb");
  if (file == NULL) {
    printf("[get_duration] Could not open file.\n");
    return 1;
  }

  WavHeader header;
  fread(&header, sizeof(WavHeader), 1, file);

  fseek(file, 0, SEEK_END);
  int fileSize = ftell(file);

  float durationSeconds =
      (float)(fileSize - sizeof(WavHeader)) / header.byteRate;

  printf("[get_duration] %s: %.2f seconds\n", wav_absolute_file_path,
         durationSeconds);

  fclose(file);
  return durationSeconds;
}