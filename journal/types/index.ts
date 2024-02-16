export type TaconezInfluxRow = {
  result: string,
  table: number,
  _start: string,
  _stop: string,
  _time: string,
  _measurement: string,
  audio_file_path: string,
  sound: string
};

export type SoundOccurrence = {
  when: Date,
  sound: string,
  audio_file_path: string
}