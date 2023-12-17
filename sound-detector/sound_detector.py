"""Detects, records and informs upon detecting specific sounds.

https://github.com/eulersson/anesowa/tree/main/sound-detector

"""

# Native Imports
import os
import datetime
import urllib.request
import tarfile
import wave
import zipfile

from typing import Any, List, Tuple, Optional

# Third-Party Imports
import influxdb_client
import pyaudio
import zmq

import numpy as np
import pandas as pd

from influxdb_client.client.write_api import SYNCHRONOUS
from numpy.typing import NDArray
from slugify import slugify


SKIP_DETECTION_NOTIFICATION = (
    os.getenv("SKIP_DETECTION_NOTIFICATION", "False") == "True"
)

INFLUX_DB_ADDR = "http://host.docker.internal:8086"
INFLUX_DB_TOKEN = os.getenv("INFLUX_DB_TOKEN")

# Endpoint where the distributor PULL socket is listening at.
# The distributor runs as a container binding 5555 to the host.
ZMQ_DISTRIBUTOR_ADDR = "tcp://host.docker.internal:5555"

# This folder is shared over NFS, therefore all other clients will be able to mount it.
# TODO: Ensure it doesn't get wiped out once we run the container again.
DETECTED_RECORDINGS_DIR = "/recordings"

SKIP_RECORDING = os.getenv("SKIP_RECORDING", "False") == "True"
if not SKIP_RECORDING:
    assert os.path.exists(
        DETECTED_RECORDINGS_DIR
    ), f"The folder {DETECTED_RECORDINGS_DIR} must exist and be shared over NFS."

# TensorFlow Lite is more optimized for a device such as the Raspberry Pi.
USE_TFLITE = os.getenv("USE_TFLITE", "True")
USE_TFLITE = USE_TFLITE == "True" or USE_TFLITE == "1"

AUDIO_FORMAT = pyaudio.paInt16
AUDIO_CHANNELS = 1

# This is the rate the YAMNet explicitely requires.
AUDIO_RATE = 16000

# Read from microphone in this amount of frames per second.
AUDIO_CHUNK = 1024

# Amount of seconds to feed into the neural network.
AUDIO_INFERENCE_SECONDS = 0.975

# The length of numpy array values before feeding into YAMNet model.
AUDIO_INFERENCE_SAMPLES = 15600

# This assertion is illustrative.
assert 15600 == AUDIO_INFERENCE_SAMPLES == (AUDIO_RATE * AUDIO_INFERENCE_SECONDS), (
    "The AUDIO_INFERENCE_SAMPLES is explicitely set to satisfy the model constraints. "
    "At the moment it uses YAMNet which requires a specific number of samples."
)

# Stripes of audio segments of individual durations of `INFERENCE_SECONDS` (~1s) that
# are treated as a single event, that way when we detect a sound in one of the segments
# of the batch we will store the entire strip of sound instead of storing only ~1s files.
AUDIO_INFERENCE_BATCH_SIZE = 5

# Allows interacting with microphone.
p = pyaudio.PyAudio()


def model_predict(model, waveform: NDArray) -> NDArray:
    """Guesses the sound category given some audio.

    Depending on the `USE_TFLITE` variable it will load one of these versions:

    - https://www.kaggle.com/models/google/yamnet/frameworks/tensorFlow2
    - https://www.kaggle.com/models/google/yamnet/frameworks/tfLite/variations/classification-tflite

    Args:
        model: A model loaded through `tensorflow_hub.load(model_name)` or
          `tflite_runtime.interpreter.Interpreter(model_path)`.
        waveform (numpy.NDArray): An array with 0.975 seconds as mono 16 kHz waveform
          samples, that is of shape (15600,) where each value is normalized between
          -1.0 and 1.0.

    Returns:
        The scores for all the classes as an array of shape (M, N). It's a
        two-dimensional list where the first dimension (M) corresponds to time slices
        and the second dimension (N) the scores for that time slice.
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
    else:
        scores, embeddings, spectrogram = model(waveform)

    return scores


# TODO: Resolve the model type better. At the moment "Any" is used.
def load_model_and_labels() -> Tuple[Any, List[str]]:
    """Loads the model to run classify audio and class names for those predictions.

    Returns:
        A model constructed with `tensorflow_hub.load(model_name)` or
        `tflite_runtime.interpreter.Interpreter(model_path)`.
    """
    if USE_TFLITE:
        print("Using TensorFlow Lite.")
        # TODO: There might be a better way to download the model from Kaggle (former TensorFlow Hub).
        model_tarball_path = os.path.join(
            os.path.dirname(__file__), "yamnet-classification.tar.gz"
        )

        if not os.path.exists(model_tarball_path):
            urllib.request.urlretrieve(
                "https://www.kaggle.com/models/google/yamnet/frameworks/TfLite/variations/classification-tflite/versions/1/download",
                model_tarball_path,
            )

        model_path = os.path.join(os.path.dirname(__file__), "1.tflite")
        if not os.path.exists(model_path):
            file = tarfile.open(model_tarball_path)
            file.extractall(".")
            file.close()

        import tflite_runtime.interpreter as tflite

        labels_file = zipfile.ZipFile(model_path).open("yamnet_label_list.txt")
        labels = [lab.decode("utf-8").strip() for lab in labels_file.readlines()]

        interpreter = tflite.Interpreter(model_path)

        input_details = interpreter.get_input_details()
        waveform_input_index = input_details[0]["index"]

        # Input: 0.975 seconds of silence as mono 16 kHz waveform samples.
        waveform = np.zeros(
            int(round(AUDIO_INFERENCE_SECONDS * 16000)), dtype=np.float32
        )

        interpreter.resize_tensor_input(
            waveform_input_index, [waveform.size], strict=True
        )
        interpreter.allocate_tensors()

        return interpreter, labels
    else:
        print("Using TensorFlow Core.")
        import tensorflow_hub as tfhub

        yamnet_model_handle = "https://tfhub.dev/google/yamnet/1"
        yamnet_model = tfhub.load(yamnet_model_handle)

        class_map_path = yamnet_model.class_map_path().numpy().decode("utf-8")
        class_names = list(pd.read_csv(class_map_path)["display_name"])

        return yamnet_model, class_names


def write_audio(frames: bytes, suffix: Optional[str] = "") -> str:
    """Writes audio frames as bytes to a file.

    Args:
        frames: The audio binary content to write.
        suffix: To suffix the resulting file with.

    Returns:
        The filename where the .wav file is saved.

    https://gist.github.com/kepler62f/9d5836a1eff8b372ddf6de43b5b74d95

    """
    if suffix:
        suffix = f"_{suffix}"

    now = datetime.datetime.now()

    # E.g. '2023-12-10T17:05:52.578411_knock.wav'
    file_name = f"{now.isoformat()}{suffix}.wav"

    # E.g. '2023/12/22'
    year_month_day_folder = os.path.join(str(now.year), str(now.month), str(now.day))

    # E.g. '2023/12/22/2023-12-10T17:05:52.578411_knock.wav'
    relative_file_path = os.path.join(year_month_day_folder, file_name)

    # E.g. '/recordings/2023/12/22/2023-12-10T17:05:52.578411_knock.wav'
    absolute_file_path = os.path.join(DETECTED_RECORDINGS_DIR, relative_file_path)

    os.makedirs(os.path.dirname(absolute_file_path), exist_ok=True)

    wave_file = wave.open(absolute_file_path, "wb")
    wave_file.setnchannels(AUDIO_CHANNELS)
    wave_file.setsampwidth(p.get_sample_size(pyaudio.paInt16))
    wave_file.setframerate(AUDIO_RATE)
    wave_file.writeframes(frames)
    wave_file.close()

    print(f"Saved sound to {absolute_file_path}.")

    return absolute_file_path


def write_db_entry(slugified_class_name, relative_sound_path):
    """Writes the sound occurrence to the Influx DB store.

    Args:
        class_name: Name of the highest scoring label the sound matches.
        relative_sound_path: Path relative to DETECTED_RECORDINGS_DIR, e.g.
          `2023/12/10/2023-12-10-16-43.wav`.
    """
    client = influxdb_client.InfluxDBClient(
        url=INFLUX_DB_ADDR, org="anesowa", token=INFLUX_DB_TOKEN
    )

    write_api = client.write_api(write_options=SYNCHRONOUS)
    p = (
        influxdb_client.Point("detections")
        .tag("sound", slugified_class_name)
        .field("soundfile", relative_sound_path)
    )
    write_api.write(bucket="anesowa", org="anesowa", record=p)


def record_audio() -> Tuple[List[NDArray], bytes]:
    """Records audio from microphone returning an array of frames.

    The underlying neural network model is YAMNet and it has the following input
    requirements:

    > The model accepts a 1-D float32 Tensor or NumPy array of length 15600 containing
    > a 0.975 second waveform represented as mono 16 kHz samples in the range [-1.0, +1.0].

    Returns:
        A list of `AUDIO_INFERENCE_BATCH_SIZE` arrays of shape (15600,)
        values of which ranging [-1.0, 1.0] and the whole stripe binary audio as
        bytes.
    """
    stream = p.open(
        format=AUDIO_FORMAT,
        channels=AUDIO_CHANNELS,
        rate=AUDIO_RATE,
        input=True,
        frames_per_buffer=AUDIO_CHUNK,
    )

    waveforms: List[NDArray] = []
    waveform_binary = b""

    for _ in range(AUDIO_INFERENCE_BATCH_SIZE):
        binary_frames = []
        samples_processed = 0
        while samples_processed < AUDIO_INFERENCE_SAMPLES:
            samples_to_read = max(
                AUDIO_CHUNK, AUDIO_INFERENCE_SAMPLES - samples_processed
            )
            data = stream.read(samples_to_read)
            binary_frames.append(data)
            samples_processed += samples_to_read

        partial_waveform_binary = b"".join(binary_frames)
        waveform = np.frombuffer(partial_waveform_binary, dtype=np.int16)
        waveform = waveform / 32768
        waveform = waveform.astype(np.float32)

        waveforms.append(waveform)
        waveform_binary += partial_waveform_binary

    stream.stop_stream()
    stream.close()

    return waveforms, waveform_binary


def detect_specific_sounds(
    model,
    labels: List[str],
    # TODO: Turn that into a file that's read from.
    ignore_sounds: List[str] = [
        "Silence",
        "Speech",
        "Snoring",
        "Music",
        "Inside, small room",
        "White noise",
        "Breathing",
        "Typing",
    ],
    detect_sounds: List[str] = ["Clip-clop"],
    zmq_socket: Optional[zmq.Socket] = None,
) -> None:
    """
    Continuously records audio segments form the microphone and passes it to the model
    to see if the prediction catches the specific sound.

    If a detection happens the analyzed audio file is written down to an NFS-shared
    folder and the subsequent parts of the pipeline are notified.

    Args:
        model: Model to use for detection.
        labels: Class names of the categories the model can recognize.
        ignore_sounds: Class names to skip to reduce noise.
        detect_sounds: Detection will happen if on high score for those categories.
        zmq_socket: Used to notify the distributor a sound has been detected.
    """
    waveforms, waveform_binary = record_audio()

    predictions: List[Tuple[str, float]] = []
    specific_sound_highest_scores = dict((n, 0.0) for n in detect_sounds)

    top_class_name = None
    for i, waveform in enumerate(waveforms):
        log_prefix = f"[{i}/{len(waveforms)}]"

        scores = model_predict(model, waveform)
        class_scores = np.mean(scores, axis=0)
        top_class_index = np.argmax(class_scores)
        top_score = class_scores[top_class_index]
        top_class_name = labels[top_class_index]

        if top_class_name not in ignore_sounds:
            predictions.append((top_class_name, top_score))
            print(f"{log_prefix} Main sound: {top_class_name} (score {top_score})")

        for sound_to_detect in detect_sounds:
            sound_index = labels.index(sound_to_detect)
            sound_score = class_scores[sound_index]

            specific_sound_highest_scores[sound_to_detect] = max(
                specific_sound_highest_scores[sound_to_detect], sound_score
            )

            if sound_score > 0:
                print(
                    f"{log_prefix} Specific sound ({sound_to_detect}) score: {sound_score}"
                )

    if len(predictions):
        print(f"Batch predictions: {predictions}")
        print(f"Batch highest scores: {specific_sound_highest_scores}")

    # TODO: Implement this value and then calibrate it.
    detected = len(predictions)

    slugified_top_class_name = ""
    if detected:
        if top_class_name not in ignore_sounds:
            slugified_top_class_name = top_class_name
        else:
            for prediction_name, prediction_value in sorted(
                predictions, key=lambda x: x[1]
            ):
                if prediction_name not in ignore_sounds:
                    slugified_top_class_name = prediction_name
                    break

        slugified_top_class_name = slugify(slugified_top_class_name, separator="_")

        print("DETECTION", top_class_name)
        if not SKIP_RECORDING:
            file_path = write_audio(waveform_binary, suffix=slugified_top_class_name)
            relative_sound_path = os.path.relpath(file_path, DETECTED_RECORDINGS_DIR)

            if not SKIP_DETECTION_NOTIFICATION:
                write_db_entry(slugified_top_class_name, relative_sound_path)

            if zmq_socket:
                zmq_socket.send(f"/mnt/nfs/anesowa/{relative_sound_path}".encode("ascii"))


if __name__ == "__main__":
    print("Running Sound Detector...")

    socket = None
    if SKIP_DETECTION_NOTIFICATION:
        print("Upon detections the distributor won't be notified.")
    else:
        # Connect to the distributor that will be notified upon detection:
        context = zmq.Context()
        print(f"Connecting to sound distribution broker at {ZMQ_DISTRIBUTOR_ADDR}.")
        socket = context.socket(zmq.PUSH)
        socket.connect(ZMQ_DISTRIBUTOR_ADDR)
        print("Connected!")

    model, labels = load_model_and_labels()

    # Run the detection loop.
    while True:
        detect_specific_sounds(model, labels, zmq_socket=socket)
