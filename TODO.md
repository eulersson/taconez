# TODO

Iteration 1:

- [x] Package Python project into a package using poetry.
- [x] Recognize audio devices from docker.
- [ ] Run the detector from the container.
- [ ] Dockerize sound-detector.
- [ ] Dockerize sound player.
- [ ] Use tensorflow lite instead of tensorflow. https://www.tensorflow.org/lite/guide
      https://www.tensorflow.org/lite/guide/python
- [ ] Package things up into services that start on boot.
- [ ] Poetry: Use install groups so on Raspberry Pi we don't install unneeded stuff.
- [ ] Record 10 seconds, run 1 second chunks on the model and if ANY detection, play the
      10 seconds.
- [ ] From sound-detection send ZeroMQ signal to sound-player to play alarm.wav 5 times.
- [ ] Share a volume with NFS between neptune.local and mars.local.
- [ ] Upon sound detection, save the .wav file in the NFS share.
- [ ] Instead of the alarm.wav now the sound-player should play the actual recorded
      sound.
- [ ] Docker and nvim to play nice?
- [ ] Test infrastructure.
- [ ] Clean organized README.
- [ ] README TOC-tree

Iteration 2:

- [ ] Start working on sound-distributor.
- [ ] Dockerize sound-distributor.
- [ ] CI GitHub Actions
