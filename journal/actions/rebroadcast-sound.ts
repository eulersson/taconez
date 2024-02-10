"use server";

import { SoundOccurrence } from "@/types";
import { ProtocolType, SocketType, ZeroMq } from 'zeromq-ts'

const PLAYBACK_DISTRIBUTOR_ADDR = `tcp://${process.env.PLAYBACK_DISTRIBUTOR_HOST}:5555`;

export async function rebroadcastSound(sound: SoundOccurrence) {
  let zmq = new ZeroMq(SocketType.subscriber, ProtocolType.tcp, PLAYBACK_DISTRIBUTOR_ADDR, {})
  const payload = {
    sound_file_path: sound.audio_file_path,
    when: sound.when.getTime() / 1000,
  };
  console.log(
    `[rebroadcastSound] Sending (to distributor ${PLAYBACK_DISTRIBUTOR_ADDR}):`,
    JSON.stringify(payload)
  );
  zmq.send(JSON.stringify(payload));
}
