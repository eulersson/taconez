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