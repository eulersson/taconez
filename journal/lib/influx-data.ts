import { InfluxDB } from "@influxdata/influxdb-client";
import { unstable_noStore as noStore } from 'next/cache';

import { SoundOccurrence, TaconezInfluxRow } from "@/types";

export async function fetchSoundOccurrences({
  from = "-1mo",
  limit = 25,
  page = 1,
} = {}): Promise<SoundOccurrence[]> {
  // unstable_noStore is preferred over export const dynamic = 'force-dynamic' as it is
  // more granular and can be used on a per-component basis
  //
  //   https://nextjs.org/docs/app/api-reference/functions/unstable_noStore
  //
  noStore();
  const queryApi = new InfluxDB({
    url: `http://${process.env.INFLUX_DB_HOST}:8086`,
    token: "no_token",
  }).getQueryApi("taconez");

  const fluxQuery =
    `from(bucket:"taconez") ` +
    `|> range(start: ${from}) ` +
    `|> filter(fn: (r) => r._measurement == "detections")` +
    `|> pivot(rowKey:["_time"], columnKey: ["_field"], valueColumn: "_value")` +
    `|> sort(columns: ["_time"], desc: true)` +
    `|> limit(n: ${limit}, offset: ${(page - 1) * limit})`;
  const result: SoundOccurrence[] = [];

  for await (const { values, tableMeta } of queryApi.iterateRows(fluxQuery)) {
    const o: TaconezInfluxRow = tableMeta.toObject(values) as TaconezInfluxRow;
    const soundOccurrence: SoundOccurrence = {
      when: new Date(o._time),
      sound: o.sound,
      audio_file_path: o._value,
    };
    result.push(soundOccurrence);
  }

  return result;
}
