#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <cjson/cJSON.h>

#include "message.h"

struct ParsedMessage parse_message(char *message)
{
  printf("[parse_message] Parsing message: %s\n", message);
  cJSON *json = cJSON_Parse(message);

  char *sound_file = cJSON_GetObjectItem(json, "sound_file")->valuestring;
  printf("[parse_message] Sound file: %s\n", sound_file);

  char *when = cJSON_GetObjectItem(json, "when")->valuestring;
  printf("[parse_message] When: %s\n", when);

  char *abs_sound_file_path = malloc(strlen("/anesowa/recordings/") + strlen(sound_file) + 1);
  strcpy(abs_sound_file_path, "/anesowa/recordings/");
  strcat(abs_sound_file_path, sound_file);
  printf("[parse_message] Absolute sound file path: %s\n", abs_sound_file_path);

  return (struct ParsedMessage){when, sound_file, abs_sound_file_path};
}
