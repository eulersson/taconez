import time

from typing import Dict

import zmq

import logging


class PlayEvents:
    _instance = None

    def __new__(cls, *args, **kwargs):
        if not isinstance(cls._instance, cls):
            cls._instance = super(PlayEvents, cls).__new__(cls, *args, **kwargs)
        return cls._instance

    def __init__(self, socket: zmq.Socket):
        self.socket = socket

        # Last time a sound was played backed over the speakers.
        self.last_play_at: int | None = None
        self.last_play_sound_duration: float | None = None
        self.last_play_preroll_duration: float | None = None

        # Duration in seconds of the last preroll that was selected.
        self.preroll_durations: Dict[str, float] = {}

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

    def pull_sound_play_events(self):
        while True:
            msg = self.socket.recv_json()
            logging.info(msg)

            if isinstance(msg, dict) and msg.get("when"):
                self.last_play_at = msg["when"]
                self.last_play_sound_duration = msg["sound_duration"]
                self.last_play_preroll_duration = msg["preroll_duration"]