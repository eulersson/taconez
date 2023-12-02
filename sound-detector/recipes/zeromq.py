import zmq

context = zmq.Context()

print("Connecting to sound distribution broker.")

socket = context.socket(zmq.PUSH)
socket.connect("tcp://host.docker.internal:5555")

socket.send(b"/here/is/a/path/to/file.wav")

print("Bye!")
