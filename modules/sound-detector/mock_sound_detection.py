import time
import zmq

c = zmq.Context()
s = c.socket(zmq.PUSH)
s.connect("tcp://playback-distributor:5555")
s.send_json(
    {
        "when": int(time.time()),
        "sound_file_path": "2024/1/27/2024-01-27T10:19:36.373235_alarm.wav",
    }
)
