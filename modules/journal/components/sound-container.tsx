import { SoundBubble } from "@/components/sound-bubble";
import { SoundOccurrence } from "@/types";

export function SoundContainer({ sounds }: { sounds: SoundOccurrence[] }) {
  return (
    <div className="flex flex-col space-y-2">
      {sounds.map((sound) => (
        <SoundBubble key={sound.sound} sound={sound} />
      ))}
    </div>
  );
}