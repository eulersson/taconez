export const dynamic = 'force-dynamic';

import { SoundOccurrence, TaconezInfluxRow } from "@/types";

import { InfluxDB } from "@influxdata/influxdb-client";

async function getData(): Promise<SoundOccurrence[]> {
  const queryApi = new InfluxDB({
    url: "http://localhost:8086",
    token: "no_token",
  }).getQueryApi("taconez");

  const fluxQuery =
    'from(bucket:"taconez") |> range(start: -1w) |> filter(fn: (r) => r._measurement == "detections")';

  const result: SoundOccurrence[] = [];

  for await (const {values, tableMeta} of queryApi.iterateRows(fluxQuery)) {
    const o: TaconezInfluxRow = tableMeta.toObject(values) as TaconezInfluxRow;
    const soundOccurrence: SoundOccurrence = {
      start: new Date(o._start),
      end: new Date(o._stop),
      sound: o.sound,
      file_path: o._value 
    }
    result.push(soundOccurrence);
  }

  return result;
}

export default async function Home() {
  const data = await getData();

  return (
    <ol>
      {data.map((v, i) => <li key={i}>{v.file_path}</li>)}
    </ol>
  )
}
