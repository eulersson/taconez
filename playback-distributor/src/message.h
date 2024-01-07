struct ParsedMessage
{
  char *when;
  char *sound_file;
  char *abs_sound_file_path;
};

struct ParsedMessage parse_message(char *message);
