import zmq
c = zmq.Context()
c.socket(zmq.PUSH)
s=c.socket(zmq.PUSH)
s.connect("tcp://playback-distributor:5555")
import time
message = {"when":int(time.time()),"sound_file_path":"2024/1/27/2024-01-27T10:22:50.569125_brass_instrument.wav"}
print(f"Sending {message}")
s.send_json(message)