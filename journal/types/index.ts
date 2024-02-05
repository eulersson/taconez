export type TaconezInfluxRow = {
  result: string;
  table: number;
  _start: string;
  _stop: string;
  _time: string;
  _value: string;
  _field: string;
  _measurement: string;
  sound: string;
};

export type SoundOccurrence = {
  start: Date,
  end: Date,
  sound: string,
  file_path: string
}