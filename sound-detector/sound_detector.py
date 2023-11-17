import time
import datetime

import pyaudio
import numpy as np
import pandas as pd

import wave

import tensorflow as tf
import tensorflow_hub as tfhub
import tensorflow_io as tfio

FRAMES_PER_BUFFER = 3200
FORMAT = pyaudio.paInt16
CHANNELS = 1
RATE = 16000
SECONDS = 1

p = pyaudio.PyAudio()


def load_model_and_labels():
    yamnet_model_handle = "https://tfhub.dev/google/yamnet/1"
    yamnet_model = tfhub.load(yamnet_model_handle)
    class_map_path = yamnet_model.class_map_path().numpy().decode("utf-8")
    class_names = list(pd.read_csv(class_map_path)["display_name"])
    return yamnet_model, class_names


model, class_names = load_model_and_labels()


def write_audio(frames):
    """
    https://gist.github.com/kepler62f/9d5836a1eff8b372ddf6de43b5b74d95
    """
    wavefile = wave.open(f"{datetime.datetime.now().isoformat()}.wav", "wb")
    wavefile.setnchannels(CHANNELS)
    wavefile.setsampwidth(p.get_sample_size(pyaudio.paInt16))
    wavefile.setframerate(RATE)
    wavefile.writeframes(frames)
    wavefile.close()


def record_audio():
    """
    Records audio from microphone returning an array of frames.

    Result:
        numpy.NDArray: Array of size (FRAMES_PER_BUFFER,) the values of which range
          between -32768 and 32768.
    """
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

    waveform_binary = b"".join(frames)

    waveform = np.frombuffer(waveform_binary, dtype=np.int16)
    waveform = waveform / 32768
    waveform = tf.convert_to_tensor(waveform, dtype=tf.float32)

    return waveform, waveform_binary


def detect_specific_sounds(detect_sounds=["Clip-clop"]):
    """
    Continuously records audio segments form the microphone and passes it to the model
    to see if the prediction catches the specific sound.
    """
    waveform, waveform_binary = record_audio()

    scores, embeddings, spectrogram = model(waveform)
    class_scores = tf.reduce_mean(scores, axis=0)
    clip_clop_index = class_names.index("Clip-clop")
    print("Clip-clop index", clip_clop_index)

    clip_clop_prediction = class_scores[clip_clop_index]
    print("Clip-clop prediction", clip_clop_prediction)

    top_class = tf.math.argmax(class_scores)
    inferred_class = class_names[top_class]

    print(f"The main sound is: {inferred_class}")

    # TODO Calibrate this value.
    if clip_clop_prediction > 0.001:
        print("DETECTED")
        write_audio(waveform_binary)


if __name__ == "__main__":
    while True:
        command = detect_specific_sounds()
