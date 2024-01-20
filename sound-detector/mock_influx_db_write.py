import zmq
c = zmq.Context()
c.socket(zmq.PUSH)
s=c.socket(zmq.PUSH)
s.connect("tcp://playback-distributor:5555")
import time
message = {"when":int(time.time()),"sound_file_path":"sample.wav"}
print(f"Sending {message}")
s.send_json(message)