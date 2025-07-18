import { SoundPage }  from "@/components/sound-page";
import { fetchSoundOccurrences } from "@/lib/influx-query";

export default async function Home() {
  const initialData = await fetchSoundOccurrences();
  return (
      <main>
        <SoundPage initialData={initialData}></SoundPage>
      </main>
  );
}
