#include <stdio.h>
#include <time.h>

long get_now() {
  time_t rawtime;
  time(&rawtime);
  return rawtime;
}