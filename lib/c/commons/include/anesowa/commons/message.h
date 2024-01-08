struct DetectorMessage
{
  char *when;
  char *sound_file;
  char *abs_sound_file_path;
};

struct DistributorMessage
{
  char *when;
  char *sound_file;
  char *abs_sound_file_path;
  int sound_duration;
  int prefix_duration;
};

struct DetectorMessage parse_detector_message(char *message);

char* write_distributor_message(struct DistributorMessage message);

struct DistributorMessage parse_distributor_message(char *message);
