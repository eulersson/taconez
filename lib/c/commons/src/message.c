#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <cjson/cJSON.h>

#include "message.h"

struct DetectorMessage parse_detector_message(char *message)
{
  printf("[parse_detector_message] Parsing message: %s\n", message);
  cJSON *json = cJSON_Parse(message);

  char *sound_file = cJSON_GetObjectItem(json, "sound_file")->valuestring;
  printf("[parse_detector_message] Sound file: %s\n", sound_file);

  char *when = cJSON_GetObjectItem(json, "when")->valuestring;
  printf("[parse_detector_message] When: %s\n", when);

  char *abs_sound_file_path = malloc(strlen("/anesowa/recordings/") + strlen(sound_file) + 1);
  strcpy(abs_sound_file_path, "/anesowa/recordings/");
  strcat(abs_sound_file_path, sound_file);
  printf("[parse_detector_message] Absolute sound file path: %s\n", abs_sound_file_path);

  return (struct DetectorMessage){when, sound_file, abs_sound_file_path};
}

struct DistributorMessage parse_distributor_message(char *message)
{
  printf("[parse_message] Parsing message: %s\n", message);
  cJSON *json = cJSON_Parse(message);

  char *sound_file = cJSON_GetObjectItem(json, "sound_file")->valuestring;
  printf("[parse_message] Sound file: %s\n", sound_file);

  char *when = cJSON_GetObjectItem(json, "when")->valuestring;
  printf("[parse_message] When: %s\n", when);

  char *abs_sound_file_path = cJSON_GetObjectItem(json, "abs_sound_file_path")->valuestring;
  printf("[parse_message] Absolute sound file path: %s\n", abs_sound_file_path);

  int sound_duration = cJSON_GetObjectItem(json, "sound_duration")->valueint;
  printf("[parse_message] Sound duration: %d\n", sound_duration);

  int prefix_duration = cJSON_GetObjectItem(json, "prefix_duration")->valueint;
  printf("[parse_message] Prefix duration: %d\n", prefix_duration);

  return (struct DistributorMessage){when, sound_file, abs_sound_file_path};
}

char* write_distributor_message(struct DistributorMessage message) {
  cJSON *json = cJSON_CreateObject();

  cJSON_AddStringToObject(json, "when", message.when);
  cJSON_AddStringToObject(json, "sound_file", message.sound_file);
  cJSON_AddStringToObject(json, "abs_sound_file_path", message.abs_sound_file_path);
  cJSON_AddNumberToObject(json, "sound_duration", message.sound_duration);
  cJSON_AddNumberToObject(json, "prefix_duration", message.prefix_duration);

  char *json_string = cJSON_Print(json);
  return json_string;
}