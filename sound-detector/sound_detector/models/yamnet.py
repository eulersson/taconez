"""
YAMNet module wrappers and helpers.
"""

import logging
import numpy as np
import pandas as pd
import os
import tarfile
import urllib.request
import zipfile

from numpy.typing import NDArray

from sound_detector.config import config
from sound_detector.exceptions import TaconezException


class YAMNetModel:
    """
    Wrapper around the model to prepare it for inference.
    """

    tflite_model_path = os.path.join(os.path.dirname(__file__), "downloads", "yamnet", "1.tflite")

    model_handle = "https://tfhub.dev/google/yamnet/1"

    def __init__(self):
        self.initialized = False

    def initialize(self):
        if config.use_tflite:
            self._initialize_tflite_model()
        else:
            self._initialize_full_model()

        self.initialized = True

    def predict(self, waveform: NDArray, return_embeddings=False) -> NDArray:
        """
        Guesses the sound category given some audio.

        Depending on the `USE_TFLITE` env var it will load one of these versions:

        - https://www.kaggle.com/models/google/yamnet/frameworks/tensorFlow2
        - https://www.kaggle.com/models/google/yamnet/frameworks/tfLite/variations/classification-tflite

        Args:
            model: A model loaded through `tensorflow_hub.load(model_name)` or
              `tflite_runtime.interpreter.Interpreter(tflite_model_path)`.
            waveform (numpy.NDArray): An array with 0.975 seconds as mono 16 kHz waveform
              samples, that is of shape (15600,) where each value is normalized between
              -1.0 and 1.0. If not 0.975 seconds, it will be sliced by the model and
              various frames will be analyzed and predicted.

        Keyword Args:
            return_embeddings (bool): Returns the embedings instead of the scores.
                Useful for retraining purposes where you want to use the internal state
                of the neural network to use as inputs to another model. Only works when
                using the full model and not TFLite.

        Returns:
            The scores for all the classes as an array of shape (M, N). It's a
            two-dimensional list where the first dimension (M) corresponds to time slices
            and the second dimension (N) the scores for that time slice.
        """
        if not self.initialized:
            raise TaconezException(
                "You must call `.initialize()` first before using the model."
            )
        if config.use_tflite:
            if return_embeddings:
                raise TaconezException(
                    "The 'return_embeddings' option is not supported when using TFLite."
                )

            interpreter = self.model

            input_details = interpreter.get_input_details()
            waveform_input_index = input_details[0]["index"]
            output_details = interpreter.get_output_details()
            scores_output_index = output_details[0]["index"]

            interpreter.set_tensor(waveform_input_index, waveform)
            interpreter.invoke()

            scores = interpreter.get_tensor(scores_output_index)
        else:
            scores, embeddings, spectrogram = self.model(waveform)

            if return_embeddings:
                return embeddings

        return scores

    def _initialize_tflite_model(self):
        """
        Loads an instance of the YAMNet TFLite model and its labels.
        """

        logging.info("Initializing YAMNet using TensorFlow Lite.")

        if not os.path.exists(self.tflite_model_path):
            self._download_tflite_model()

        labels_file = zipfile.ZipFile(self.tflite_model_path).open(
            "yamnet_label_list.txt"
        )
        class_names = [lab.decode("utf-8").strip() for lab in labels_file.readlines()]

        import tflite_runtime.interpreter as tflite

        interpreter = tflite.Interpreter(self.tflite_model_path)

        input_details = interpreter.get_input_details()
        waveform_input_index = input_details[0]["index"]

        # Input: 0.975 seconds of silence as mono 16 kHz waveform samples.
        waveform = np.zeros(
            int(round(config.audio_inference_seconds * 16000)), dtype=np.float32
        )

        interpreter.resize_tensor_input(
            waveform_input_index, [waveform.size], strict=True
        )
        interpreter.allocate_tensors()

        self.model = interpreter
        self.class_names = class_names

    def _download_tflite_model(self) -> str:
        """
        Downloads YAMNet TFLite model and extracts its contents so they can be loaded.

        Returns:
            Path to the TFLite model (it's a `.tflite` file).
        """
        # TODO: There might be a better way to download the model from Kaggle (former TensorFlow Hub).
        model_tarball_path = os.path.join(
            os.path.dirname(__file__), "downloads", "yamnet", "yamnet-classification.tar.gz"
        )

        if not os.path.exists(model_tarball_path):
            urllib.request.urlretrieve(
                "https://www.kaggle.com/models/google/yamnet/frameworks/TfLite/variations/classification-tflite/versions/1/download",
                model_tarball_path,
            )

        if not os.path.exists(self.tflite_model_path):
            file = tarfile.open(model_tarball_path)
            file.extractall(os.path.dirname(self.tflite_model_path))
            file.close()

    def _initialize_full_model(self):
        """
        Loads an instance of the YAMNet model and its labels.

        This is not the TFLite version, so it's better for debugging or development.
        """

        logging.info("Initializing YAMNet full (not using TensorFlow Lite).")
        import tensorflow_hub as tfhub

        model_handle = "https://tfhub.dev/google/yamnet/1"
        model = tfhub.load(model_handle)

        class_map_path = model.class_map_path().numpy().decode("utf-8")

        self.model = model
        self.class_names = list(pd.read_csv(class_map_path)["display_name"])
