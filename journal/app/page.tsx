import { SoundPlot } from "@/components";
import { fetchSoundOccurrences } from "@/lib";

export default async function Home() {
  const initialData = await fetchSoundOccurrences();
  return (
    <>
      <p>Taconez:</p>
      <SoundPlot initialData={initialData}></SoundPlot>
    </>
  );
}
