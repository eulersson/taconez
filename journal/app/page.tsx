import { SoundPlot } from "@/components/sound-plot";
import { fetchSoundOccurrences } from "@/lib/influx-data";

export default async function Home() {
  const initialData = await fetchSoundOccurrences();
  return (
    <main>
      <SoundPlot initialData={initialData}></SoundPlot>
    </main>
  );
}
