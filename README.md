# anesowa: (A)nnoying (Ne)ighbour (So)nic (Wa)rfare

AI IoT Raspberry Pi powered solution to detect, analyse and react against discomforting
high heel sounds by projecting them back to their source.

## Motivation

My neighbour upstairs decided to walk on high heels. I expressed my discomfort and she
took it as a personal attack, rejecting all kind of mediation. Since I received insults
I decided to use the mirror strategy to see if she realizes how unpleasant it becomes:
to bounce back her sounds.

## Description

This project is composed of various pieces:

| Module               | Purpose                                                                                                            |
| -------------------- | ------------------------------------------------------------------------------------------------------------------ |
| Sound Detector       | Discriminate and pick up specific sounds using AI.                                                                 |
| Playback Distributor | Route the detected sound and bounce it back from multiple speakers on multiple locations.                          |
| Sound Player         | Play any given sound when told by the distributor.                                                                 |
| Journal (Web App)    | Visualize the sound occurrences. Useful to have an objective overview. If case gets to lawyers it might be useful. |

## Technology

This is intended to be run in a group of Raspberry Pi

| Tool                 | Purpose                                                      | Why (Reason)                                                                                                                                                                                                                                                                                                                                                                 |
| -------------------- | ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| TensorFlow (Python)  | Audio detection                                              | Provides even a higher level API (Keras) that simplifies machine learning workflows. Also provides a lightweight runtime (TF Lite) for running only inference (feeding the input and getting the output on a saved model).                                                                                                                                                   |
| Next.js (JavaScript) | Data visualization web application.                          | Allows splitting a React application between server and client components (full-stack framework), allowing you to dispatch the database queries from the server and return a rendered React component with all the data displayed, encapsulating database interaction only server-side. Allows writing REST-style API endpoints that can be listening to the sound detector. |
| InfluxDB             | Noise occurrence log.                                        | A time-series database seems very appropiate considering the nature of the data (timestamped). Chosen in favour of Prometheus because it supports `string` data types and it's PUSH-based instead of PULL-based. We don't want to lose occurrences!                                                                                                                          |
| NFS                  | Sharing a volume with the audio data.                        | The database should not get bloated with binary data. Once the audio file is producted, it gets hashed it and stored in the NFS-shared file system so it can get played by the `sound-player`.                                                                                                                                                                               |
| ZeroMQ               | Communication between audio detector and playback receivers. | Instead of having to implement an API, since it's only one instruction, it's simpler to use a PUB-SUB pipeline in the fashion of a queue. The detector places an element and all playback receivers react playing back the sound. A full queue broker installation might be overkill for a simple IoT communication channel.                                                 |
| Docker               | Containerization.                                            | Protects against underlaying operating system components that might get updated and break the app.                                                                                                                                                                                                                                                                           |
| Ansible              | Provisioning and deployment.                                 | Automates some base configuration installation on new Raspberry Pi hosts, such as the sound setup.                                                                                                                                                                                                                                                                           |

## Architecture

![Diagram](anesowa.svg)

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./anesowa.drawio.dark.svg">
  <img alt="Architecture Diagram" src="./anesowa.drawio.light.svg">
</picture>

Under each folder in this repository you will find more information about the particular
piece.

- [sound-detector](sound-detector)
- [sound-player](sound-player)
- [playback-distributor](playback-distributor)

## Documentation

If you are only interested in the deployment:

| Document                                         | Explains How To...                                                                                  |
| ------------------------------------------------ | --------------------------------------------------------------------------------------------------- |
| [Provisioning](docs/1-provisioning.md)           | Flash a new card, plug into a Raspberry Pi and provision it as **master** or **slave**              |
| [Raspberry Pi Sound Setup](2-rpi-sound-setup.md) | Connect multiple Bluetooth speakers, create a combined sink of various speakers, set up microphone. |

If you are interested in how to get a development environment and how the issues of
running container sound on the host (be it a MacBook or a Raspberry Pi):

| Document                                              | Explains How To...                                                                                                                                            |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Docker Container Sound](3-docker-container-sound.md) | Offer host audio I/O to the container through PulseAudio's TCP interface.                                                                                     |
| [Development Workflow](4-development-workflow.md)     | Develop the application container on a non-Pi host with keeping the LSP IDE features and still be able to use the microphone and speakers through PulseAudio. |
| [Stack Recipes](5-stack-recipes.md)                   | Run hello worlds, proof of concepts and basic examples with the stack tools: InfluxDB, NFS and Ansible.                                                       |
| [AI: Transfer Learning](5-transfer-learning.md)       | Repurpose an already trained classification neural network to classify specific sounds.                                                                       |

## Development Workflow

### Container Development

Thanks to this
[reddit comment](https://www.reddit.com/r/neovim/comments/y1hryr/comment/iry6c0q/) we
see it's possible to run a language server within our app's container and tell our IDE
to connect to it.

First build the container:

```
eulersson@macbook:~/Devel/anesowa $ docker build \
  --build-arg="DEBUG=1" \
  --build-arg="INSTALL_DEV_DEPS=1" \
  --build-arg="USE_TFLITE=0" \
  -t anesowa/sound-detector:1.0.0-dev \
  ./sound-detector
```

Then run a container as follows:

```
eulersson@macbook:~/Devel/anesowa $ docker run -it \
  --name anesowa-pyright-dev-container \
  -v $(pwd):/anesowa/sound-detector \
  --add-host dev-hack:127.0.0.1 \
  --net host \
  --hostname dev-hack \
  --entrypoint /bin/bash \
  --init \
  --detach \
  anesowa/sound-detector:1.0.0-dev
```

When you are done you working remember to stop and delete the container:

```
eulersson@macbook:~ $ docker stop --time 0 anesowa-pyright-dev-container
eulersson@macbook:~ $ docker rm anesowa-pyright-dev-container
```

Now depending on your IDE the steps will differ, but basically you need to configure the
pyright language server command to be the one from the container using `docker exec`:

#### LunarVim / NeoVim

If using LunarVim open up `~/.config/lvim/config.lua` and add these lines:

```lua
require("lvim.lsp.manager").setup("pyright", {
  -- TODO: I still haven't figured out yet is how to switch the cmd out on a per project
  -- basis. I'd like to only use this weird pyright setup in my main dev project, but
  -- then use regular (Mason installed) pyright outside of docker in general.
  cmd = {
    "docker",
    "exec",
    "-i",
    "anesowa-pyright-dev-container",
    "pyright-langserver",
    "--stdio",
  },
  single_file_support = true,
  settings = {
    pyright = {
      disableLanguageServices = false,
      disableOrganizeImports = false
    },
    python = {
      analysis = {
        autoImportCompletions = true,
        autoSearchPaths = true,
        diagnosticMode = "workspace", -- openFilesOnly, workspace
        typeCheckingMode = "basic",   -- off, basic, strict
        useLibraryCodeForTypes = true
      }
    }
  },
  before_init = function(params)
    -- LSP spec has a default flag that will cause you some trouble; if an LSP server
    -- can't find its parent's processId, it will shut itself down after a second or so.
    -- You need to tell it to ignore the processId shutdown behaviour (or start your
    -- docker container to share the process space with your host).
    params.processId = vim.NIL
  end,
})
```

**TODO**: Chose the pyright container execution on a per-project basis, and if not
defined then use the regular way by using the one installed by the Mason in LunarVim.

If using NeoVim open up your lua file, e.g. `~/.config/nvim/init.lua` and add:

```
local lspconfig = require('lspconfig')
lspconfig.pyright.setup {
  ... <PUT HERE THE { cmd {...}, settings {...}, python {...} ... } AFOREMENTIONED> ...
}
```

### Microphone & Speaker

Read the guide on [Docker Container Sound](#docker-container-sound) to make sure you
have PulseAudio installed on your host machine with the `module-native-protocol-tcp`
enabled.

### Iterative Development

During my development from the macOS

Syncing the changes manually with `rsync`:

```
eulersson@macbook:~ $ rsync \
  -e "ssh -i ~/.ssh/raspberrypi_key.pub" -azhP \
  --exclude "sound-player/build/" --exclude ".git/" --exclude "*.cache*" \
  . anesowa@rpi-master.local:/home/user/anesowa
```

Then running the corresponding `docker run` volume-binding the project folder:

```
anesowa@rpi-master:~/anesowa/sound-detector $ docker run ... -v $(pwd):/anesowa/sound-detector ...
```

PROS:

- Only the changed files are synced.
- It is secure and encrypted.

CONS:

- It's a manual action.
- Only syncs towards a single target machine.
- Deleted files are not handled.

I also evaluated other workflows such as `lsyncd`, `distant` and `distant.nvim` or
simply having a network volume and working on there but each had caveats. I explain why
I discarded them in [Discarded Tools](#discarded-tools).

### LSP Features

#### Poetry

The `sound-detector` Python project uses `poetry` to handle dependencies. To develop on
your local machine:

```
# Install dependencies. Poetry will place them on a virtual environment.
eulersson@macbook:~/Devel/anesowa $ poetry install

# See where the virtual environment is installed.
eulersson@macbook:~/Devel/anesowa $ poetry env info

Virtualenv
Python:         3.10.13
Implementation: CPython
Path:           /Users/eulersson/Library/Caches/pypoetry/virtualenvs/sound-detector-CXfsoo8U-py3.10
Executable:     /Users/eulersson/Library/Caches/pypoetry/virtualenvs/sound-detector-CXfsoo8U-py3.10/bin/python
Valid:          True

System
Platform:   darwin
OS:         posix
Python:     3.10.13
Path:       /Users/eulersson/.pyenv/versions/3.10.13
Executable: /Users/eulersson/.pyenv/versions/3.10.13/bin/python3.10
```

Now that you know the virtual env lives in
`/Users/eulersson/Library/Caches/pypoetry/virtualenvs/sound-detector-CXfsoo8U-py3.10`
add a `pyrightconfig.json` on the root of the Python project
`~/Devel/anesowa/sound-detector/pyrightconfig.json`:

```
{
   "venv" : "sound-detector-oq1WgInS-py3.11",
   "venvPath" : "/Users/ramon/Library/Caches/pypoetry/virtualenvs"
}
```

This will help `pyright` LSP to be able to understand and resolve the project.

## Database (InfluxDB)

This project uses **InfluxDB**, a times series database is to be used to log disturbing
sound occurrences.

These guides are used as reference:

- [Install InfluxDB on Raspberry Pi](https://docs.influxdata.com/influxdb/v2/install/?t=Raspberry+Pi)
- [InfluxDB Docs | Get started writing data](https://docs.influxdata.com/influxdb/v2/get-started/write)
- [InfluxDB Docs | Get started querying data](https://docs.influxdata.com/influxdb/v2/get-started/query)

**NOTE**: This document is a reference, and you don't need to provision new Raspberry
Pis with those commands since it's done with an Ansible playbook. This is for me to
remember the steps before writing the Ansible Playbook. Read
[Provisioning (Ansible)](#provisioning-ansible) for more.

### Installation

Installing InfluxDB server:

```
anesowa@rpi-master:~ $ uudo apt update
anesowa@rpi-master:~ $ sudo apt upgrade
anesowa@rpi-master:~ $ curl https://repos.influxdata.com/influxdata-archive.key | gpg --dearmor | sudo tee /usr/share/keyrings/influxdb-archive-keyring.gpg >/dev/null
anesowa@rpi-master:~ $ echo "deb [signed-by=/usr/share/keyrings/influxdb-archive-keyring.gpg] https://repos.influxdata.com/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
anesowa@rpi-master:~ $ sudo apt install influxdb2
anesowa@rpi-master:~ $ sudo systemctl unmask influxdb
anesowa@rpi-master:~ $ sudo systemctl enable influxdb
anesowa@rpi-master:~ $ sudo systemctl start influxdb
```

```
curl -O https://dl.influxdata.com/influxdb/releases/influxdb2_2.7.4-1_arm64.deb
sudo dpkg -i influxdb2_2.7.4-1_arm64.deb
sudo service influxdb start


```

```
# amd64
wget https://dl.influxdata.com/influxdb/releases/influxdb2-client-2.7.3-linux-amd64.tar.gz
```

### Configuration

```
# Setup instance with initial user, org, bucket.
anesowa@rpi-master:~ $ influx setup \
  --username anesowa \
  --password ">R7#$gjf>2@dLXUU<" \
  --token XwSAJxRKHFkFL9wLiA4pPrDeXed
  --org anesowa \
  --bucket anesowa \
  --force

# Create an All Access API Token to use when creating resources on the database.
anesowa@rpi-master:~ $ influx auth create \
  --all-access \
  --host http://localhost:8086 \
  --org anesowa \
  --token XwSAJxRKHFkFL9wLiA4pPrDeXed
ID                      Description     Token                                                                                           User Name       User ID                 Permissions
0c0d6b05a3a6d000                        MkNsrWGwIpZEZvyRGK49-ftUgqoQCmY4rmisobotxxPr_M_Cx_IBxjge_KgOQUswdQr2tmFjzDLmRetkfg0qcg==        supermaster          0c0d68543ca6d000        [read:orgs/8e706e7c04613c15/authorizations write:orgs/8e706e7c04613c15/authorizations read:orgs/8e706e7c04613c15/buckets write:orgs/8e706e7c04613c15/buckets read:orgs/8e706e7c04613c15/dashboards write:orgs/8e706e7c04613c15/dashboards read:/orgs/8e706e7c04613c15 read:orgs/8e706e7c04613c15/sources write:orgs/8e706e7c04613c15/sources read:orgs/8e706e7c04613c15/tasks write:orgs/8e706e7c04613c15/tasks read:orgs/8e706e7c04613c15/telegrafs write:orgs/8e706e7c04613c15/telegrafs read:/users/0c0d68543ca6d000 write:/users/0c0d68543ca6d000 read:orgs/8e706e7c04613c15/variables write:orgs/8e706e7c04613c15/variables read:orgs/8e706e7c04613c15/scrapers write:orgs/8e706e7c04613c15/scrapers read:orgs/8e706e7c04613c15/secrets write:orgs/8e706e7c04613c15/secrets read:orgs/8e706e7c04613c15/labels write:orgs/8e706e7c04613c15/labels read:orgs/8e706e7c04613c15/views write:orgs/8e706e7c04613c15/views read:orgs/8e706e7c04613c15/documents write:orgs/8e706e7c04613c15/documents read:orgs/8e706e7c04613c15/notificationRules write:orgs/8e706e7c04613c15/notificationRules read:orgs/8e706e7c04613c15/notificationEndpoints write:orgs/8e706e7c04613c15/notificationEndpoints read:orgs/8e706e7c04613c15/checks write:orgs/8e706e7c04613c15/checks read:orgs/8e706e7c04613c15/dbrp write:orgs/8e706e7c04613c15/dbrp read:orgs/8e706e7c04613c15/notebooks write:orgs/8e706e7c04613c15/notebooks read:orgs/8e706e7c04613c15/annotations write:orgs/8e706e7c04613c15/annotations read:orgs/8e706e7c04613c15/remotes write:orgs/8e706e7c04613c15/remotes read:orgs/8e706e7c04613c15/replications write:orgs/8e706e7c04613c15/replications]

# Configure connection configuration preset to use.
anesowa@rpi-master:~ $ influx config create \
  --config-name anesowa \
  --host-url http://localhost:8086 \
  --org anesowa \
  --token MkNsrWGwIpZEZvyRGK49-ftUgqoQCmY4rmisobotxxPr_M_Cx_IBxjge_KgOQUswdQr2tmFjzDLmRetkfg0qcg==
Active  Name            URL                     Org
        anesowa         http://localhost:8086   anesowa

# Generate timestamps with:
anesowa@rpi-master:~ $ date +%s
1698755458

# Create an entry:
anesowa@rpi-master:~ $ influx write --bucket anesowa --precision s "
acons,sound=high_heel soundfile=\"/path/to/soundfile.wav\" $(date +%s)
"

# Querying:
anesowa@rpi-master:~ $ influx query 'from(bucket: "anesowa") |> range(start: 2020-10-10T08:00:00Z, stop: 2024-10-10T08:00:00Z) |> filter(fn: (r) => r.\_measurement == "annoying_sounds")'
Result: \_result
Table: keys: [_start, _stop, _field, _measurement, room]
\_start:time \_stop:time \_field:string \_measurement:string room:string \_time:time \_value:string

---

2020-10-10T08:00:00.000000000Z 2024-10-10T08:00:00.000000000Z soroll tacons neus 2023-10-31T12:38:54.000000000Z /path/to/file.wav
Table: keys: [_start, _stop, _field, _measurement, room]
\_start:time \_stop:time \_field:string \_measurement:string room:string \_time:time \_value:string

---

2020-10-10T08:00:00.000000000Z 2024-10-10T08:00:00.000000000Z soroll tacons tete 2023-10-31T15:11:45.984090516Z /to/file2.wav
```

Using the Python client (`pip install influxdb-client`) is easy:

```
import influxdb_client
from influxdb_client.client.write_api import SYNCHRONOUS

client = influxdb_client.InfluxDBClient(
url="http://localhost:8086",
org="anesowa",
token="MkNsrWGwIpZEZvyRGK49-ftUgqoQCmY4rmisobotxxPr_M_Cx_IBxjge_KgOQUswdQr2tmFjzDLmRetkfg0qcg==",
)

write_api = client.write_api(write_options=SYNCHRONOUS)
p = influxdb_client.Point("annoying_sounds").tag("sound", "high_heel").field("soundfile", "/to/file2.wav")
write_api.write(bucket="anesowa", org="anesowa", record=p)

```

## File Sharing (NFS)

This project uses **NFS** for synchronizing the audio detections so they can be replayed
in all the Raspberry Pis.

The master Raspberry Pi should set up an NFS share mounted on `/mnt/nfs/anesowa` so that
all slaves can connect to it.

Considerations:

- Only allow connecting within the local network.
- Only allow the operating user of the stack (in my case `anesowa`) to connect to it.
  When trying to connect from another environment the UNIX user and password will then
  be required instead of allowing anonymous connections.

Hardening should be studied on a second iteration.

These guides is taken as reference:

- [How to Setup Raspberry Pi NFS Server](https://pimylifeup.com/raspberry-pi-nfs/)
- [Connecting to an NFS Share on the Raspberry Pi](https://pimylifeup.com/raspberry-pi-nfs-client/)
- [The /etc/exports Configuration File](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/5/html/deployment_guide/s1-nfs-server-config-exports)

**NOTE**: This guide assumes the master Raspberry Pi runs at `192.168.1.76` in the
network.

**NOTE**: This document is a reference, and you don't need to provision new Raspberry
Pis with those commands since it's done with an Ansible playbook. This is for me to
remember the steps before writing the Ansible Playbook. Read
[Provisioning](/docs/provisioning.md) for more.

### Server Setup

Run this on the Raspberry Pi:

```
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install nfs-kernel-server -y
sudo mkdir -p /mnt/nfs/anesowa
sudo chown -R anesowa:anesowa /mnt/nfs/anesowa
sudo find /mnt/nfs/anesowa/ -type d -exec chmod 755 {} \;
sudo find /mnt/nfs/anesowa/ -type f -exec chmod 644 {} \;

```

Get the user that will be used on anonymous users.

```
# TODO: Do not allow anonymous access.
id anesowa
# Output: <anesowa-id>
```

Open file `/etc/exports` and set this line, replacing `192.168.1/24` with your local
network CIDR. This determines from where connections will be accepted:

```
/mnt/nfs/anesowa 192.168.1.0/24(rw,all_squash,insecure,no_subtree_check,anonuid=1000,anongid=1000)
```

- `insecure` is needed otherwise from macOS I cannot connect from macOS.

Export the changes:

```
sudo exportfs -ra
```

### Connecting from a macOS

To connect using _File Explorer > Go > Connect to Server_ (<kbd>⌘</kbd> + <kbd>K</kbd>)
and type in `nfs://rpi-master.local/mnt/nfs/anesowa`.

### Connecting from Other Raspberry Pi

If nfs-common is not installed, install it (it usually is installed by default).

```
sudo apt update
sudo apt full-upgrade
sudo apt install nfs-common
```

Then create a folder and mount the network volume to that folder:

```
sudo mkdir -p /mnt/nfs/anesowa
sudo chmod 755 /mnt/nfs/anesowa
sudo mount -t nfs rpi-master.local:/mnt/nfs/anesowa /mnt/nfs/anesowa
```

## Provisioning (Ansible)

TODO: Do an Ansible playbook for:

- Raspberry Pi Zero
- Rasbperry Pi 3 B
- Raspberry Pi 4

Where you do something like:

```
deploy --type raspberry-pi-zero 192.168.0.55
```

So the Raspberry Pi type should be parametrized.

### Things to Translate Into Ansible Playbook

#### Docker

Docker is needed on the Raspberry Pis:

```
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```

```
docker run hello-world
```

#### Raspberry Pi < 4

Those Raspberry Pis will need an explicit install of the **PulseAudio** system, because
otherwise they only run on **ALSA**.

```
sudo apt install pulseaudio pulseaudio-module-bluetooth
```

## Sound Player

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

## Sound Detector

**ADVICE**: Generate the `poetry.lock` from the container running in the Raspberry Pi.

Live recording the microphone with
[pyaudio](https://people.csail.mit.edu/hubert/pyaudio/) feeding it to a TensorFlow
YAMNet retrained model.

I used transfer learning on the [YAMNet model](https://tfhub.dev/google/yamnet/1) that
has been trained on the [AudioSet data](https://research.google.com/audioset/) to narrow
it down to my particular case of high heel detection.

- [Transfer learning with YAMNet for environmental sound classification](https://www.tensorflow.org/tutorials/audio/transfer_learning_audio)
- [Build your own real-time voice command recognition model with TensorFlow](https://www.youtube.com/watch?v=m-JzldXm9bQ)
- [Realtime Voice Command Recognition](https://github.com/AssemblyAI-Examples/realtime-voice-command-recognition)
- [Quickstart for Linux-based devices with Python](https://www.tensorflow.org/lite/guide/python)
- [Simple Audio Recognition on a Raspberry Pi using Machine Learning (I2S, TensorFlow Lite)](https://electronut.in/audio-recongnition-ml/)
- [Download TF Lite from TF Hubt](https://www.kaggle.com/models/google/yamnet/frameworks/tfLite)
- [TensorFlow Lite Python audio classification example with Raspberry Pi](https://github.com/tensorflow/examples/tree/master/lite/examples/audio_classification/raspberry_pi)
- [Model I/O](https://www.tensorflow.org/lite/guide/inference#load_and_run_a_model_in_python)

To run the Jupyter Notebook you will need the pip `notebook` package installed, then:

```
jupyter notebook transfer_learning.ipynb
```

### Docker

```
anesowa@rpi-master:~/anesowa $ docker build -t anesowa/sound-player:1.0.0 ./sound-player
```

On one shell:

```
anesowa@rpi-master:~ $ pactl load-module module-native-protocol-tcp
```

On the other:

```
anesowa@rpi-master:~ $ docker run --rm -it \
  --add-host host.docker.internal:host-gateway \
  -e PULSE_SERVER host.docker.internal \
  -v $HOME/.config/pulse/cookie:/root/.config/pulse/cookie \
  anesowa/sound-detector:1.0.0
```

### Dependencies

This Python project uses the [poetry](https://python-poetry.org/) packaging and
dependency management tool.

In my case my LSP of my editor won't pick up the dependencies because `poetry`
encapsulates them.

You can either run a `poetry shell` and open the text editor or install them with pip on
your python installation (`pyenv` in my case). You can also run a Python console with
`poetry run python`.

First make sure Python is compliant with the python version specified in
`pyproject.toml`:

```
[tool.poetry.dependencies]
python = "^3.11,<3.12"
```

If it's not the case use pyenv to install the right version.

Follow the
[official installation instructions](https://github.com/pyenv/pyenv#installation):

```
curl https://pyenv.run | bash

# Then add the following in the ~/.bashrc
#
#   export PYENV_ROOT="$HOME/.pyenv"
#   [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
#   eval "$(pyenv init -)"
#   eval "$(pyenv virtualenv-init -)"
#
```

Then you can install and set the correct Python version:

```
# If on the Raspberry Pi install development OpenSSL libraries before building Python
#
#   https://github.com/pyenv/pyenv/wiki/Common-build-problems#error-the-python-ssl-extension-was-not-compiled-missing-the-openssl-lib
#
sudo apt install libssl-dev

pyenv install 3.11.5
```

Now activate the installation:

```
# Remember to revert to the system-installed Python afterwards `pyenv global system`.
pyenv global 3.11.5
```

Install the system libraries that will be needed for building the python packages:

```
sudo apt install portaudio19-dev
```

Then you can proceed to install poetry, the package management tool that is more aware
of the dependency resolution. Follow the
[official instructions](https://python-poetry.org/docs/#installation):

```
# On macOS / Linux:
pip install


# On Raspberry:
pip install --upgrade pip \
 && pip install --upgrade keyrings.alt \ # TODO: Needed?
 && pip install poetry \
 && poetry config virtualenvs.create false \
 && poetry install --no-interaction
```

**NOTE**: This will install only tflite-runtime and will not install the tensorflow core
packages. If you want to install core packages (for development) then pass the
dependency group on the CLI command `poetry install --with tensorflow-dev` (see
`pyproject.toml`) to see the `tensorflow-dev` group.

Now to install the dependencies on Raspberry Pi:

```
# Avoid hanging by disabling the keyring backend.
#
#   https://stackoverflow.com/a/60804443
#
export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring
poetry install # Choose whether you want tensorflow core packages with `--with tensorflow-dev`.
```

### TensorFlow Lite

- [Saving a Model](https://www.tensorflow.org/guide/keras/serialization_and_saving)
- [Converting to a Lite Model](https://www.tensorflow.org/lite/models/convert/convert_models)
- [Running Inference](https://www.tensorflow.org/lite/guide/python)

## Discarded Tools

### Discarded Alternative 1: lsyncd

Lsyncd (Live Syncing Daemon) synchronizes local directories with remote targets.

It uses rsync and ssh under the hood every time it detects a filesystem event.

I discarded it because the mantainer himself said it is not reliable on macOS:

> the osx events interface of Lsyncd is generally very outdated, and as far as I know
> unmaintained, unless someone finds willing to do that, and best rewrite it all
> together to use FSEvents insted of that experiment I did back then to directly access
> the internal buffer, I'd advice against using it, or removing it from Lsyncd
> altogether.
>
> Source: https://github.com/lsyncd/lsyncd/issues/204#issuecomment-1794164518

### Discarded Alternative 2: Distant + distant.nvim

- https://distant.dev/
- https://distant.dev/editors/neovim/installation/

Installing a **distant** service on the Raspberry Pi and connecting to it via **Neovim**
is possible. You would be able to browse through the remote files from Neovim and open
them up with your local Neovim resources.

PROS:

- Good for connecting to resources that might be outside of the network.
- The communication is efficient and fast because it goes through custom TCP _distant_
  protocol between the _distant_ client and _distant_ server.
- It's encrypted.

CONS:

- I couldn't get the language server features working, it seemed to rely on me
  installing all the intellisense tooling on the Raspberry Pi, which I prefer not
  because the compute power of my computer is better than the Pi.
- Code would not reside in my powerful computer.
- I would have to sync from that Raspberry Pi to the rest of them.

### Discarded Alternative 3: Network Volume Binding

We could bind a folder from the Raspberry Pi and make it available in the LAN (local)
network with `NFS` or `SMB` or if I'm outside the local network I could use an encrypted
ssh-filesystem connection `sshfs` or tunnel into my LAN NFS with OpenVPN (that would
make me have to install VPN software on my LAN and client machine).

PROS:

- Transparent to navigate the mounted remote volume.
- Intellisense (LSP) would work.

CONS:

- The actual code would reside in a Raspberry Pi machine instead of my local filesystem.
- If the Raspberry Pi gets corrupted I lose all the code.
- I would have to sync from that Raspberry Pi to the rest of them.
