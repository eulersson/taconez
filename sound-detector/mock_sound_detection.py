import time
import zmq

c = zmq.Context()
s = c.socket(zmq.PUSH)
s.connect("tcp://playback-distributor:5555")
s.send_json(
    {
        "when": int(time.time()),
        "sound_file_path": "2024/1/20/2024-01-20T15:11:15.914063_finger_snapping.wav",
    }
)
