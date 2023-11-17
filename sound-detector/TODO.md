Iteration 1:
- [ ] Record 10 seconds, run 1 second chunks on the model and if ANY detection, play the 10 seconds.
- [ ] From sound-detection send ZeroMQ signal to sound-player to play alarm.wav 5 times.
- [ ] Share a volume with NFS between neptune.local and mars.local.
- [ ] Upon sound detection, save the .wav file in the NFS share.
- [ ] Instead of the alarm.wav now the sound-player should play the actual recorded sound.
- [ ] Package things up into services that start on boot.

Iteration 2:
- [ ] Start working on sound-distributor.
