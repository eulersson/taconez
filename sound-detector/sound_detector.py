import os
import datetime
import urllib.request
import wave
import zipfile

import pyaudio

import numpy as np
import pandas as pd

USE_TFLITE = os.getenv("USE_TFLITE", "True")
USE_TFLITE = USE_TFLITE == "True" or USE_TFLITE == "1"

FRAMES_PER_BUFFER = 3900
FORMAT = pyaudio.paInt16
CHANNELS = 1
RATE = 16000
SECONDS = 0.975

p = pyaudio.PyAudio()


def model_predict(model, labels, waveform):
    """
    Args:
        model (model or interpreter) TODO DOCUMENT THIS.
        waveform (numpy.NDArray) An array with 0.975 seconds of silence as mono 16 kHz,
            waveform samples, that is of shape (15600,) where each value is normalized
            between -1.0 and 1.0.
    """
    if USE_TFLITE:
        interpreter = model

        input_details = interpreter.get_input_details()
        waveform_input_index = input_details[0]["index"]
        output_details = interpreter.get_output_details()
        scores_output_index = output_details[0]["index"]

        interpreter.set_tensor(waveform_input_index, waveform)
        interpreter.invoke()

        scores = interpreter.get_tensor(scores_output_index)
        print(scores.shape)  # Should print (1, 521)

        top_class_index = scores.argmax()
        print(len(labels))  # Should print 521
        print(labels[top_class_index])  # Should print 'Silence'.
    else:
        scores, embeddings, spectrogram = model(waveform)

    return scores


def load_model_and_labels():
    if USE_TFLITE:
        model_path = os.path.join(
            os.path.dirname(__file__), "yamnet-classification.tflite"
        )
        if not os.path.exists(model_path):
            urllib.request.urlretrieve(
                "https://www.kaggle.com/models/google/yamnet/frameworks/TfLite/variations/classification-tflite/versions/1/download",
                model_path,
            )

        import tflite_runtime.interpreter as tflite

        labels_file = zipfile.ZipFile(model_path).open("yamnet_label_list.txt")
        labels = [lab.decode("utf-8").strip() for lab in labels_file.readlines()]

        interpreter = tflite.Interpreter(model_path)

        input_details = interpreter.get_input_details()
        waveform_input_index = input_details[0]["index"]
        output_details = interpreter.get_output_details()
        scores_output_index = output_details[0]["index"]

        # Input: 0.975 seconds of silence as mono 16 kHz waveform samples.
        waveform = np.zeros(int(round(0.975 * 16000)), dtype=np.float32)
        print(waveform.shape)  # Should print (15600,)

        interpreter.resize_tensor_input(
            waveform_input_index, [waveform.size], strict=True
        )
        interpreter.allocate_tensors()
        model_predict(interpreter, labels, waveform)

        return interpreter, labels
    else:
        import tensorflow_hub as tfhub

        yamnet_model_handle = "https://tfhub.dev/google/yamnet/1"
        yamnet_model = tfhub.load(yamnet_model_handle)

        class_map_path = yamnet_model.class_map_path().numpy().decode("utf-8")
        class_names = list(pd.read_csv(class_map_path)["display_name"])

        return yamnet_model, class_names



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
    # TODO: Improve this since now 16000 / 3900 * 0.975 = 4 (4.0), but if you change any
    # variable it would lead to floating point values which would then skip reading the
    # last needed chunk.
    for i in range(0, int(RATE / FRAMES_PER_BUFFER * SECONDS) + 1):
        data = stream.read(FRAMES_PER_BUFFER)
        frames.append(data)

    stream.stop_stream()
    stream.close()

    waveform_binary = b"".join(frames)

    waveform = np.frombuffer(waveform_binary, dtype=np.int16)
    waveform = waveform / 32768
    waveform = waveform.astype(np.float32)

    return waveform, waveform_binary


# TODO: Implement detect_sounds.
def detect_specific_sounds(model, labels, detect_sounds=["Clip-clop"]):
    """
    Continuously records audio segments form the microphone and passes it to the model
    to see if the prediction catches the specific sound.
    """
    waveform, waveform_binary = record_audio()

    scores = model_predict(model, labels, waveform)

    class_scores = np.mean(scores, axis=0)
    clip_clop_index = labels.index("Clip-clop")
    print("Clip-clop index", clip_clop_index)

    clip_clop_prediction = class_scores[clip_clop_index]
    print("Clip-clop prediction", clip_clop_prediction)

    top_class = np.argmax(class_scores)
    inferred_class = labels[top_class]

    print(f"The main sound is: {inferred_class}")

    # TODO: Calibrate this value.
    if clip_clop_prediction > 0.0001:
        print("DETECTED")
        write_audio(waveform_binary)


if __name__ == "__main__":
    model, labels = load_model_and_labels()

    while True:
        command = detect_specific_sounds(model, labels)
