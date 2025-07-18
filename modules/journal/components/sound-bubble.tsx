import { SoundOccurrence } from "@/types";

export function SoundBubble({ sound }: { sound: SoundOccurrence }) {
  return (
    <div className="h-200 bg-tz-red">{sound.audio_file_path}</div>
  );
}
