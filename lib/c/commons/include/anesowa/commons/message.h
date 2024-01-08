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
  float sound_duration;
  float preroll_duration;
};

struct DetectorMessage parse_detector_message(char *message);

char* write_distributor_message(struct DistributorMessage *message);

struct DistributorMessage parse_distributor_message(char *message);
