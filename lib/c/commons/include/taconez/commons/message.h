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

// =====================================================================================
// Message Definition (message.h)
//
// Definition of the messages that are exchanged between the detector and the
// distributor and functions to parse them.
//
// =====================================================================================

#ifndef MESSAGE_H
#define MESSAGE_H

struct DetectorMessage
{
  long when;
  char *sound_file_path;
  char *abs_sound_file_path;
};

struct DistributorMessage
{
  long when;
  char *sound_file_path;
  char *abs_sound_file_path;
  char *preroll_file_path;
  char *abs_preroll_file_path;
  double sound_duration;
  double preroll_duration;
};

struct DetectorMessage parse_detector_message(char *message);

char* write_distributor_message(struct DistributorMessage *message);

struct DistributorMessage parse_distributor_message(char *message);

#endif