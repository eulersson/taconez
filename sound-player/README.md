# anesowa: Sound Player

Plays a specific sound when the [Sound Distributor](/sound-distributor) notifies it.

See the [Architecture](/#architecture) section on the root [README.md](/) for more.

TODO: Translate the following into Dockerfile and document how to get sound from it
from the container to the host.

```
# Install CMake for building Makefiles.
sudo apt install cmake

# If the Raspberry Pi is older than 4 (uses Debian bullseye intead of bookworm) you
# will need to install libpulse-dev.
sudo apt install libpulse-dev

# On macOS you would need the pulse audio libraries too
brew install pulseaudio
```

Compile with:

```
cd sound-player
cmake -S . -B build
cmake --build build --verbose
./sound_player /usr/share/sounds/alsa/Front_Center.wav
```

