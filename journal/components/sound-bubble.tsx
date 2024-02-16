import { rebroadcastSound } from "@/actions";
import { SoundOccurrence } from "@/types";

export function SoundBubble({ sound }: { sound: SoundOccurrence }) {
  // TODO: See what would happen if `async` was removed from the function signature.
  const onPlayButtonClick = async () => {
    const audio = new Audio(`/api/sound/${sound.audio_file_path}`);
    audio.play();
  };

  // TODO: See what would happen if `async` was removed from the function signature.
  const onRebroadcastButtonClick = async () => {
    rebroadcastSound(sound);
  };

  return (
    <div className="flex">
      <span>{sound.when.toISOString()}</span>
      <span className="text-sm text-gray-500">{sound.audio_file_path}</span>
      <button onClick={onPlayButtonClick}>Play</button>
      <button onClick={onRebroadcastButtonClick}>Rebroadcast</button>
    </div>
  );
}
