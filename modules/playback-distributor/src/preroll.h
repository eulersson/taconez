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
// Preroll (preroll.h)
//
// Functions to interact with the preroll files.
//
// =====================================================================================

#ifndef PREROLL_H
#define PREROLL_H

/**
 * Chooses a preroll file randomly from the /app/prerolls folder.
 * 
 * NOTE: Remember to free the returned string.
 *
 * NOTE: It could be implemented with a linked list but I do not consider worth the
 * effort because it might sacrifice readibility for such a simple task and we would
 * need to iterate over the list to locate and free the items anyway.
 */
char *randomly_choose_preroll_file();

#endif