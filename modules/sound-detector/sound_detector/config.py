"""
Configuration management from environment variables.
"""

import os
import logging

import pyaudio
from environs import Env

env = Env()
env.read_env()


class _Config:
    """Holds settings used across the application.

    It's a singleton, so it's instantiated only once and the same instance is used
    across the application. Do not use this class but instead import the `config`
    instance from this module.

    Example:

    ```python
    from sound_detector.config import config
    debug = config.debug
    ```
    """

    _instance = None

    def __new__(cls, *args, **kwargs):
        if not isinstance(cls._instance, cls):
            cls._instance = super(_Config, cls).__new__(cls, *args, **kwargs)
        return cls._instance

    def __init__(self):
        # Indicates development mode, so it might not run in an optimized way.
        self.debug = env.bool("DEBUG", True)

        # Verbosity of the logging and its configuration.
        self.logging_level = env.str("LOGGING_LEVEL", "INFO")
        logging.basicConfig(
            format="[%(filename)s:%(funcName)s:%(lineno)s] %(levelname)s %(message)s",
            level=self.logging_level,
        )

        # Identifies the particular host that is running the inference.
        self.machine_id = env.str("MACHINE_ID", "rpi")

        # Whether it is a `master` or a `slave`.
        self.machine_role = env.str("MACHINE_ROLE", "slave")

        # Use TFLite or the full TensorFlow model. TFLite is faster and uses less memory.
        # It's used for inference only.
        self.use_tflite = env.bool("USE_TFLITE", True)

        # Where to save the recordings (and prerolls)
        self.detected_recordings_dir = "/app/recordings"
        self.prerolls_dir = "/app/prerolls"

        # Means it's not running inference mode, but it's running the training mode.
        self.retrain_network = env.bool("RETRAIN_NETWORK", False)

        # Whether recordings should be saved or not.
        self.skip_recording = env.bool("SKIP_RECORDING", False)

        if not self.retrain_network and not self.skip_recording:
            assert os.path.exists(self.detected_recordings_dir), (
                f"The folder {self.detected_recordings_dir} must exist and be shared "
                "over NFS when running the inference mode!"
            )

        # Influx DB settings.
        self.influx_db_host = env.str(
            "INFLUX_DB_HOST", required=(not self.skip_recording)
        )
        self.influx_db_addr = f"http://{self.influx_db_host}:8086"
        self.influx_db_token = env.str("INFLUX_DB_TOKEN", None)

        # The host where the playback distributor is running at.
        self.playback_distributor_host = env.str(
            "PLAYBACK_DISTRIBUTOR_HOST", required=True
        )

        # If enabled it won't propagate the detection to the playback distributor.
        self.skip_detection_notification = env.bool(
            "SKIP_DETECTION_NOTIFICATION", False
        )

        # ZeroMQ configuration. The address to push when a detection is made and the
        # endpoint to pull updates when a sound is being played back so we halt
        # detecting during so to avoid feedback.
        self.zmq_distributor_push_addr = f"tcp://{self.playback_distributor_host}:5555"
        self.zmq_distributor_sub_addr = f"tcp://{self.playback_distributor_host}:5556"

        # The "monitor" mode is useful for gathering sound data and see what
        # categories are detected (unless it is in the `IGNORE_SOUNDS`). The
        # "detection" mode is useful when you want to react against a specific
        # category of sound.
        self.stealth_mode = env.bool("STEALTH_MODE", False)

        # Use the retrained model (we used transference learning to binary classify high
        # heel sounds) or use YAMNet as is to identify certain sound occurrences.
        self.use_retrained_model = env.bool("USE_RETRAINED_MODEL", True)

        if self.use_retrained_model:
            self.retrained_model_path = env.str("RETRAINED_MODEL_PATH", required=True)

        if self.use_retrained_model:
            self.retrained_model_output_threshold = env.float(
                "RETRAINED_MODEL_OUTPUT_THRESHOLD", required=True
            )
        else:
            self.multiclass_detection_threshold = env.float(
                "MULTICLASS_DETECTION_THRESHOLD", 0.3
            )
            self.multiclass_detect_sounds = env.list("MULTICLASS_DETECT_SOUNDS", [])
            self.multiclass_ignore_sounds = []
            with open("./.multiclass-ignore-sounds", "r") as f:
                self.multiclass_ignore_sounds = f.read().splitlines()

        self.audio_format = pyaudio.paInt16
        self.audio_channels = 1
        self.audio_rate = 16000
        self.audio_chunk = 1024
        self.audio_inference_seconds = 0.975
        self.audio_inference_samples = 15600

        # This assertion is illustrative.
        assert (
            15600
            == self.audio_inference_samples
            == (self.audio_rate * self.audio_inference_seconds)
        ), (
            "The AUDIO_INFERENCE_SAMPLES is explicitely set to satisfy the model constraints. "
            "At the moment it uses YAMNet which requires a specific number of samples (15600), "
            "and the audio_rate and audio_inference_seconds does not honour this constraint."
        )

        self.audio_inference_batch_size = 5

    def print_config(self):
        # Print the value of each class attribute to see the configuration values:
        print("Configuration:")
        for k, v in self.__dict__.items():
            print(f"\t{k}: {v}")


config = _Config()
