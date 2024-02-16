"use client";

import { useCallback, useState } from "react";

import { rebroadcastSound } from "@/actions/rebroadcast-sound";
import { Button } from "@/components/button";
import { SoundOccurrence } from "@/types";

export function SoundBubble({ sound }: { sound: SoundOccurrence }) {
  const [playing, setPlaying] = useState(false);

  // TODO: See what would happen if `async` was removed from the function signature.
  const onPlayButtonClick = useCallback(async () => {
    const audio = new Audio(`/api/sound/${sound.audio_file_path}`);
    audio.onplay = () => {
      setPlaying(true);
    };
    audio.onended = () => {
      console.log("finished playing sound");
      setPlaying(false);
    };
    audio.play();
  }, []);

  // TODO: See what would happen if `async` was removed from the function signature.
  const onRebroadcastButtonClick = async () => {
    rebroadcastSound(sound);
  };

  return (
    <div className="flex space-x-1 items-center">
      <Button onClick={onPlayButtonClick}>{playing ? "..." : "Play"}</Button>
      <Button onClick={onRebroadcastButtonClick}>Rebroadcast</Button>
      <span>{sound.when.toISOString()}</span>
      <span className="text-sm text-gray-500">{sound.audio_file_path}</span>
    </div>
  );
}
