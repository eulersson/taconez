export type TaconezInfluxRow = {
  result: string,
  table: number,
  _start: string,
  _stop: string,
  _time: string,
  _measurement: string,
  sound: string,
  audio_file_path: string,
  score: number
};

export type SoundOccurrence = {
  when: Date,
  id: string,
  category: string,
  score: number,
  audio_file_path: string
}

export enum TimeRange {
  Day = "Day",
  Week = "Week",
  Month = "Month"
}
