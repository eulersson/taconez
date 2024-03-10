# Copyright [Year] [Your Name or Your Organization's Name]
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Detects, records and informs upon detecting specific sounds."""

import logging
import os
import time
import threading
import wave
from datetime import datetime
from typing import Dict, List, Optional, Tuple

import numpy as np
import pyaudio
import zmq
from numpy.typing import NDArray

# Allows interacting with microphone.
p = pyaudio.PyAudio()


if __name__ == "__main__":
    logging.info("Running Sound Detector...")
