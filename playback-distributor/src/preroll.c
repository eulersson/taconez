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
