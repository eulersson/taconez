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
// Duration Helpers (duration.h)
//
// This file contains the definition of the functions that are used to calculate the
// duration of a WAV file.
//
// =====================================================================================

// Get the duration of a WAV file as seconds.
float get_duration(char* wav_absolute_file_path);
