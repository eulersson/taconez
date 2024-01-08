#include <time.h>

int get_now() {
  time_t rawtime;
  struct tm *timeinfo;
  timeinfo = localtime(&rawtime);
  return timeinfo;
}