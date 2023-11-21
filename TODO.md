# TODO

Iteration 1:

- [x] Package Python project into a package using poetry.
- [x] Recognize audio devices from docker.
- [ ] Run the detector from the container.
- [x] Dockerize sound-detector.
- [x] Dockerize sound player.
- [ ] Use tensorflow lite instead of tensorflow. https://www.tensorflow.org/lite/guide
      https://www.tensorflow.org/lite/guide/python
- [ ] Record 10 seconds, run 1 second chunks on the model and if ANY detection, play the
      10 seconds.
- [ ] Network: Share a volume with NFS between rpi-master.local and rpi-slave-1.local.
- [ ] Distributor: Work on a registry system for the distributor to know how many
      connections.
- [ ] ZeroMQ: From sound-detection send ZeroMQ signal to sound-distributor so it sends
      it to sound-player to play alarm.wav 5 times.
- [ ] Detector: Upon sound detection, save the .wav file in the NFS share.
- [ ] Detector: Instead of the alarm.wav now the sound-player should play the actual
      recorded sound.
- [ ] Workflow: Docker and nvim to play nice?
- [ ] Test: Test infrastructure.
- [ ] Doc: Clean organized README.
- [ ] Doc: README TOC-tree
- [ ] Ansible: Package things up into services that start on boot.

Iteration 2:

- [ ] Start working on sound-distributor.
- [ ] Dockerize sound-distributor.
- [ ] CI GitHub Actions
- [ ] Move the sound-detector base python-slim to python-alpine and see if TensorFlow
      works.
- [ ] Poetry: Use install groups so on Raspberry Pi we don't install unneeded stuff.
