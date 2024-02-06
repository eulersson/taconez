import { unstable_noStore as noStore } from 'next/cache'
import { InfluxDB } from "@influxdata/influxdb-client";

import { SoundOccurrence, TaconezInfluxRow } from "@/types";

async function getData(): Promise<SoundOccurrence[]> {
  const queryApi = new InfluxDB({
    // TODO: Make this an environment variable (influx-db-server -> INFLUX_DB_HOST).
    url: `http://${process.env.INFLUX_DB_HOST}:8086`,
    token: "no_token",
  }).getQueryApi("taconez");

  const fluxQuery =
    'from(bucket:"taconez") |> range(start: -4w) |> filter(fn: (r) => r._measurement == "detections")';

  const result: SoundOccurrence[] = [];

  for await (const { values, tableMeta } of queryApi.iterateRows(fluxQuery)) {
    const o: TaconezInfluxRow = tableMeta.toObject(values) as TaconezInfluxRow;
    const soundOccurrence: SoundOccurrence = {
      start: new Date(o._start),
      end: new Date(o._stop),
      sound: o.sound,
      file_path: o._value,
    };
    result.push(soundOccurrence);
  }

  return result;
}

export async function SoundPlot() {
  // unstable_noStore is preferred over export const dynamic = 'force-dynamic' as it is
  // more granular and can be used on a per-component basis
  //
  //   https://nextjs.org/docs/app/api-reference/functions/unstable_noStore
  //
  noStore();
  const data = await getData();
  return (
    <>
      <p>Number of items: {data.length} </p>
      <ol>
        {data.map((v, i) => (
          <li key={i}>{v.file_path}</li>
        ))}
      </ol>
    </>
  );
}