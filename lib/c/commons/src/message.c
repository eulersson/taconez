#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <cjson/cJSON.h>

#include "message.h"

struct DetectorMessage parse_detector_message(char *message)
{
  printf("[parse_detector_message] Parsing message: %s\n", message);
  cJSON *json = cJSON_Parse(message);

  long when = cJSON_GetObjectItem(json, "when")->valueint;
  printf("[parse_detector_message] When: %ld\n", when);

  char *sound_file_path = cJSON_GetObjectItem(json, "sound_file_path")->valuestring;
  printf("[parse_detector_message] Sound file path: %s\n", sound_file_path);

  char *abs_sound_file_path = malloc(strlen("/anesowa/recordings/") + strlen(sound_file_path) + 1);
  strcpy(abs_sound_file_path, "/anesowa/recordings/");
  strcat(abs_sound_file_path, sound_file_path);
  printf("[parse_detector_message] Absolute sound file path: %s\n", abs_sound_file_path);

  return (struct DetectorMessage){when, sound_file_path, abs_sound_file_path};
}

struct DistributorMessage parse_distributor_message(char *message)
{
  printf("[parse_message] Parsing message: %s\n", message);
  cJSON *json = cJSON_Parse(message);

  long when = cJSON_GetObjectItem(json, "when")->valueint;
  printf("[parse_message] When: %ld\n", when);

  char *sound_file_path = cJSON_GetObjectItem(json, "sound_file_path")->valuestring;
  printf("[parse_message] Sound file path: %s\n", sound_file_path);

  char *abs_sound_file_path = cJSON_GetObjectItem(json, "abs_sound_file_path")->valuestring;
  printf("[parse_message] Absolute sound file path: %s\n", abs_sound_file_path);

  char *preroll_file_path = cJSON_GetObjectItem(json, "preroll_file_path")->valuestring;
  printf("[parse_message] Preroll file path: %s\n", preroll_file_path);

  char *abs_preroll_file_path = malloc(strlen("/anesowa/recordings/") + strlen(preroll_file_path) + 1);
  strcpy(abs_preroll_file_path, "/anesowa/recordings/");
  strcat(abs_preroll_file_path, preroll_file_path);
  printf("[parse_detector_message] Absolute prefix file path: %s\n", abs_preroll_file_path);

  int sound_duration = cJSON_GetObjectItem(json, "sound_duration")->valuedouble;
  printf("[parse_message] Sound duration: %d\n", sound_duration);

  int preroll_duration = cJSON_GetObjectItem(json, "preroll_duration")->valuedouble;
  printf("[parse_message] Preroll duration: %d\n", preroll_duration);

  return (struct DistributorMessage){
    when,
    sound_file_path,
    abs_sound_file_path,
    preroll_file_path,
    abs_preroll_file_path,
    sound_duration,
    preroll_duration
  };
}

char* write_distributor_message(struct DistributorMessage *message) {
  cJSON *json = cJSON_CreateObject();

  cJSON_AddNumberToObject(json, "when", message->when);
  cJSON_AddStringToObject(json, "sound_file_path", message->sound_file_path);
  cJSON_AddStringToObject(json, "abs_sound_file_path", message->abs_sound_file_path);
  cJSON_AddStringToObject(json, "preroll_file_path", message->preroll_file_path);
  cJSON_AddStringToObject(json, "abs_preroll_file_path", message->abs_preroll_file_path);
  cJSON_AddNumberToObject(json, "sound_duration", message->sound_duration);
  cJSON_AddNumberToObject(json, "preroll_duration", message->preroll_duration);

  char *json_string = cJSON_Print(json);
  return json_string;
}
