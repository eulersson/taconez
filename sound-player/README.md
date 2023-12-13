# Sound Player

Plays a specific sound when the [Sound Distributor](/docs/sound-distributor) notifies it.

See the [Architecture](/#architecture) section on the root [README.md](/) for more.

## Development Workflow

I recommend having a look at the general documents first:

- [General Development Workflow](/docs/4-development-workflow.md)
- [Docker Container Sound](/docs/3-docker-container-sound.md)

You can choose to either develop using a container or not. It's easier to develop using
a container (running the IDE from the host), you can still have LSP features like
autocompletion and suggestions! But I realized some of them do not work, like jumping to
a python library file that's outside the project: if you jump to the definition of a
third-party import the local Neovim will try to open a file that exists on the container
and not the host.

So you are free to choose:

| Method                                                                              | Advantages                                                                   | Disadvantages                                                                                                                                                                                               |
| ----------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Local Development](#local-development)                                             | Full LSP features, including "Go to definition" on third party libraries     | You have to install some system dependencies: `pyenv`, `poetry`, `portaudio`, ...                                                                                                                           |
| [Container Development (IDE from Host)](#container-development-running-ide-in-host) | System project dependencies are solved by the container build's instructions | You neeed to configure the IDE to run the container's LSP servers instead of the host's and some features like "Go to definition" on third-party libs don't work because the host doesn't have those files. |

### Local Development

On your host (be it Debian-based (Rasperry Pi OS, Ubuntu,...) or macOS):

```
# Install CMake for building Makefiles.
sudo apt install cmake

# If the Raspberry Pi is older than 4 (uses Debian bullseye intead of bookworm) you
# will need to install libpulse-dev.
sudo apt install libpulse-dev

# On macOS you would need the pulse audio libraries too
brew install pulseaudio
```

If you use an LSP such as clangd and want to work locally, for clangd to work you need
to generate the `compile_commands.json` database. The instructions for generating it is
already on the [CMakeLists.txt](CMakeLists.txt) file, therefore you only need to build
the project locally:

```
cd sound-player
cmake -S . -B build --fresh
cmake --build build --verbose
```

Try to play a sound with:

```
./build/test_play_sound ../sample.wav
```

The main program entrypoint is `./build/sound_player`

### Container Development (Running IDE in Host)

```
eulersson@macbook:~/Devel/anesowa $ ./sound-player/docker/build_dev.sh
```

```
eulersson@macbook:~/Devel/anesowa $ docker run \
  --rm -it -e PULSE_SERVER=host.docker.internal \
  -v $HOME/.config/pulse/cookie:/root/.config/pulse/cookie \
  -v $(pwd):/sample.wav  \
  anesowa/sound-player:1.0.0 paplay /sample.wav
```
