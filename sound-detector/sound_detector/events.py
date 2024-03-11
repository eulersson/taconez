import time
import threading

from typing import Dict

import zmq

import logging

from sound_detector.config import config
from sound_detector.exceptions import TaconezException


class PlayEventsManager:
    _instance = None

    def __new__(cls, *args, **kwargs):
        if not isinstance(cls._instance, cls):
            cls._instance = super(PlayEventsManager, cls).__new__(cls, *args, **kwargs)
        return cls._instance

    def __init__(self, context: zmq.Context):
        if config.skip_detection_notification:
            raise TaconezException(
                "This class should not be used when `skip_detection_notification` is set to True."
            )

        sub_addr = config.zmq_distributor_sub_addr
        self.sub_socket = context.socket(zmq.SUB)

        logging.info(f"Connecting to sound distribution broker at {sub_addr}.")
        self.sub_socket.connect(sub_addr)
        logging.info(f"Connected ZMQ SUB socket ({sub_addr}).")

        # Subscribe to all messages
        self.sub_socket.setsockopt_string(zmq.SUBSCRIBE, "")


        # Last time a sound was played backed over the speakers.
        self.last_play_at: int | None = None
        self.last_play_sound_duration: float | None = None
        self.last_play_preroll_duration: float | None = None

        # Duration in seconds of the last preroll that was selected.
        self.preroll_durations: Dict[str, float] = {}

        self.thread = threading.Thread(
            target=self.periodically_pull_sound_play_events, daemon=True
        )

    def start(self):
        self.thread.start()

    def has_been_recording_while_sound_was_playing(self) -> bool:
        """Check if sound had been playing last few seconds to avoid analyzing sound that
        was recorded while a speaker was playing a recorded sound and hence avoid feedback
        speaker-microphone.
        """
        if self.last_play_at:
            seconds_since_last_play = round(time.time()) - self.last_play_at
            is_sound_playing = seconds_since_last_play < (
                self.last_play_sound_duration + self.last_play_preroll_duration
            )
            if not is_sound_playing:
                logging.info("[last_play_*] Resetting values.")
                self.last_play_at = None
                self.last_play_sound_duration = None
                self.last_play_preroll_duration = None
            return is_sound_playing

    def periodically_pull_sound_play_events(self):
        while True:
            msg = self.sub_socket.recv_json()
            logging.info(msg)

            if isinstance(msg, dict) and msg.get("when"):
                self.last_play_at = msg["when"]
                self.last_play_sound_duration = msg["sound_duration"]
                self.last_play_preroll_duration = msg["preroll_duration"]
