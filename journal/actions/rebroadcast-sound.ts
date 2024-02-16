"use server";

import { SoundOccurrence } from "@/types";
import { Push } from "zeromq";

const PLAYBACK_DISTRIBUTOR_ADDR = `tcp://${process.env.PLAYBACK_DISTRIBUTOR_HOST}:5555`;

export async function rebroadcastSound(sound: SoundOccurrence) {
  console.log(`[rebroadcastSound] Re-broadcasting sound:`, sound);
  const sock = new Push;
  console.log(`[rebroadcastSound] Binding to ${PLAYBACK_DISTRIBUTOR_ADDR}...`)
  sock.connect(PLAYBACK_DISTRIBUTOR_ADDR)

  const payload = {
    sound_file_path: sound.audio_file_path,
    when: new Date().getTime() / 1000,
  };
  console.log(
    `[rebroadcastSound] Sending (to distributor ${PLAYBACK_DISTRIBUTOR_ADDR}):`,
    JSON.stringify(payload)
  );
  await sock.send(JSON.stringify(payload));
}
