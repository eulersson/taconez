// ====================================================================================
// Sound Player Module (sound_player.c)
//
// Listens to the distributor to receive sound files to play.
// ====================================================================================

// Native
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/fcntl.h>
#include <time.h>
#include <unistd.h>

// Third-Party
#include <cjson/cJSON.h>
#include <pulse/error.h>
#include <pulse/simple.h>
#include <zmq.h>

// Project
#include <anesowa/commons/utils.h>

#define BUFSIZE 2048

// The sample format to use.
static const pa_sample_spec ss = {
    .format = PA_SAMPLE_S16LE, .rate = 16000, .channels = 1};

// Uses PulseAudio simple API to play a sound. The input given to it is an
// absolute file path of a .wav file.
int play_sound(char *sound_file) {
  printf("[player] Playing sound file: %s\n", sound_file);

  pa_simple *s = NULL;
  int ret = 1;
  int error;

  int fd;

  if ((fd = open(sound_file, O_RDONLY)) < 0) {
    fprintf(stderr, __FILE__ ": open() failed: %s\n", strerror(errno));
    return errno;
  }

  if (dup2(fd, STDIN_FILENO) < 0) {
    fprintf(stderr, __FILE__ ": dup2() failed: %s\n", strerror(errno));
    return errno;
  }

  close(fd);

  // Create a new playback stream.
  if (!(s = pa_simple_new(NULL, sound_file, PA_STREAM_PLAYBACK, NULL,
                          "playback", &ss, NULL, NULL, &error))) {
    fprintf(stderr, __FILE__ ": pa_simple_new() failed: %s\n",
            pa_strerror(errno));
  }

  for (;;) {
    uint8_t buf[BUFSIZE];
    ssize_t r;

    // Read some data.
    if ((r = read(STDIN_FILENO, buf, sizeof(buf))) <= 0) {
      if (r == 0) {
        break;
      }
      fprintf(stderr, __FILE__ ": read() failed: %s\n", strerror(errno));
      return errno;
    }

    // And play it.
    if (pa_simple_write(s, buf, (size_t)r, &error) < 0) {
      fprintf(stderr, __FILE__ ": pa_simple_write() failed: %s",
              pa_strerror(error));
      return error;
    }
  }

  return EXIT_SUCCESS;
}

int main(void) {
  void *context = zmq_ctx_new();
  void *sub_socket = zmq_socket(context, ZMQ_SUB);
  zmq_connect(sub_socket, "tcp://host.docker.internal:5556");
  zmq_setsockopt(sub_socket, ZMQ_SUBSCRIBE, "", 0);

  printf("[player] Ready!\n");

  while (1) {
    char *message = s_recv(sub_socket);

    printf("[player] Received: %s\n", message);

    cJSON *json = cJSON_Parse(message);
    char* sound_file = cJSON_GetObjectItem(json, "sound_file")->valuestring;
    char* when = cJSON_GetObjectItem(json, "when")->valuestring;

    char* abs_sound_file_path = strcat("/anesowa/recordings/", sound_file);

    time_t rawtime;
    struct tm * timeinfo;
    timeinfo = localtime(&rawtime);

    printf("[distributor] When: %s\n", when);
    printf("[distributor] Now: %s\n", asctime(timeinfo));
    printf("[distributor] Sound file path: %s\n", abs_sound_file_path);

    // TODO: Play pre-roll.
    play_sound(abs_sound_file_path);

    int finished = strcmp(message, "exit") == 0;
    free(message);
    if (finished) {
      break;
    }
  }

  printf("[player] Bye!\n");
  zmq_close(sub_socket);
  zmq_ctx_destroy(context);
  return 0;
}
