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

#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

char *randomly_choose_preroll_file()
{
    DIR *d;
    struct dirent *dir;
    d = opendir("/app/prerolls");

    srand(time(NULL));

    int max_prerolls = 0;
    while ((dir = readdir(d)) != NULL)
    {
        if (
            strcmp(dir->d_name, ".") != 0 && strcmp(dir->d_name, "..") != 0)
        {
            max_prerolls++;
        }
    }

    char **prerolls = malloc(max_prerolls * sizeof(char *));
    int i = 0;
    rewinddir(d);
    while ((dir = readdir(d)) != NULL)
    {
        if (
            strcmp(dir->d_name, ".") != 0 && strcmp(dir->d_name, "..") != 0 && strcmp(dir->d_name, ".gitkeep") != 0)
        {
            prerolls[i] = dir->d_name;
            i++;
        }
    }

    int chosen_preroll_index = rand() % i;
    char *file_path = prerolls[chosen_preroll_index];
    char *preroll_file_path = malloc(strlen(file_path) + 1);

    strcpy(preroll_file_path, file_path);
    printf("[distributor] Preroll file path: %s\n", preroll_file_path);

    // NOTE: Do not close it before strcopying the file path, because it will be freed.
    closedir(d);

    return preroll_file_path;
}
