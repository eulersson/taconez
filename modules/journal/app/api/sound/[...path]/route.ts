import fs from "fs";
import path from "path";
import { ReadableOptions } from "stream";

import { NextRequest, NextResponse } from "next/server";


/**
 * Given an absolute path on the server file system, returns a readable stream to be
 * return into a response so the client can pull the file in chunks.
 */
function streamFile(path: string, options?: ReadableOptions): ReadableStream<Uint8Array> {
  const downloadStream = fs.createReadStream(path, options);
  return new ReadableStream({
    start(controller) {
      downloadStream.on("data", (chunk: Buffer) => controller.enqueue(new Uint8Array(chunk)));
      downloadStream.on("end", () => controller.close());
      downloadStream.on("error", (err) => controller.error(err));
    },
    cancel() {
      downloadStream.destroy();
    }
  })
}

/**
 * Serves the recorded sounds to be played by the client locally.
 *
 * E.g. `GET /api/sounds/2024/1/27/2024-01-27T10:12:00.431431_highheels.wav` would
 * return the sound file on the server in
 * `/app/recordings/2024/1/27/2024-01-27T10:12:00.431431_highheels.wav.`
 *
 * Sources:
 * - https://github.com/vercel/next.js/discussions/15453#discussioncomment-6748645
 */
export async function GET(request: NextRequest) {
  const url = new URL(request.url);
  const absFilePath = url.pathname.replace("/api/sound/", "/app/recordings/");

  const fileStat = await fs.promises.stat(absFilePath);
  const data = streamFile(absFilePath);
  return new NextResponse(
    data,
    {
      status: 200,
      headers: {
        "Content-Disposition": `attachment; filename="${path.basename(absFilePath)}"`,
        "Content-Type": "audio/wav",
        "Content-Length": fileStat.size.toString(),
      },
    }
  );
}
