# https://stackoverflow.com/questions/6951046/how-to-play-an-audiofile-with-pyaudio

import time
import pyaudio

FRAMES_PER_BUFFER = 3200
FORMAT = pyaudio.paInt16
CHANNELS = 1
RATE = 16000
SECONDS = 1

p = pyaudio.PyAudio()

def record_audio():
    stream = p.open(
        format=FORMAT,
        channels=CHANNELS,
        rate=RATE,
        input=True,
        frames_per_buffer=FRAMES_PER_BUFFER,
    )

    frames = []
    for i in range(0, RATE // FRAMES_PER_BUFFER * SECONDS):
        data = stream.read(FRAMES_PER_BUFFER)
        frames.append(data)


    stream.stop_stream()
    stream.close()

    return frames

def play_recorded_sound(frames):
    stream = p.open(
        format=FORMAT,
        channels=CHANNELS,
        rate=RATE,
        output=True,
        frames_per_buffer=FRAMES_PER_BUFFER,
    )

    for i in range(1):
        for frame in frames:
            stream.write(frame)

    time.sleep(1)

    stream.close()

if __name__ == "__main__":
    while True:

        print("recording...")
        data = record_audio()
        print("done recording")
        print("playing sound")
        play_recorded_sound(data)
        print("done playing sound")
        print("done sleeping 5")
    
