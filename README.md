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

| Tool                 | Purpose                                              | Why (Reason)                                                                                                                                                                                                                                                                                                                                                                 |
| -------------------- | ---------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| TensorFlow (Python)  | Audio detection                                      | Provides even a higher level API (Keras) that simplifies machine learning workflows. Also provides a lightweight runtime (TF Lite) for running only inference (feeding the input and getting the output on a saved model).                                                                                                                                                   |
| Next.js (JavaScript) | Data visualization web application.                  | Allows splitting a React application between server and client components (full-stack framework), allowing you to dispatch the database queries from the server and return a rendered React component with all the data displayed, encapsulating database interaction only server-side. Allows writing REST-style API endpoints that can be listening to the sound detector. |
| InfluxDB             | Noise occurrence log.                                | A time-series database seems very appropiate considering the nature of the data (timestamped). Chosen in favour of Prometheus because it supports `string` data types and it's PUSH-based instead of PULL-based. We don't want to lose occurrences!                                                                                                                          |
| NFS                  | Sharing a volume with the audio data.                | The database should not get bloated with binary data. Once the audio file is producted, it gets hashed it and stored in the NFS-shared file system so it can get played by the `sound-player`.                                                                                                                                                                               |
| ZeroMQ               | Communication audio detector <-> playback receivers. | Instead of having to implement an API, since it's only one instruction, it's simpler to use a PUB-SUB pipeline in the fashion of a queue. The detector places an element and all playback receivers react playing back the sound. A full queue broker installation might be overkill for a simple IoT communication channel.                                                 |
| Docker               | Containerization.                                    | Protects against underlaying operating system components that might get updated and break the app.                                                                                                                                                                                                                                                                           |
| Ansible              | Provisioning and deployment.                         | Automates some base configuration installation on new Raspberry Pi hosts, such as the sound setup.                                                                                                                                                                                                                                                                           |

## Architecture

![Diagram](anesowa.svg)

Under each folder in this repository you will find more information about the particular
piece.

- [sound-detector](sound-detector)
- [sound-player](sound-player)
- [playback-distributor](playback-distributor)

## Preparing SD for Raspberry Pi

Use the official [Raspberry Pi Imager](https://www.raspberrypi.com/software/) to create
microSD cards with Raspberry OS.

First create a keypair to use when connecting to the Raspberry Pis:

```
ssh-keygen -t ed25519 -C "anesowa@raspberrypi"
```

Before flashing the card it asks you if you want OS customization, click "Edit
settings".

- Hostname: `rpi-master`, `rpi-slave-1`, `rpi-slave-2`, ...
- Set username: `anesowa`.
- Set password.
- Configure wireless LAN.
- Services > Enable SSH: ON
- Allow public-key authentication only > Set authorized_keys for 'anesowa': copy the
  public key from the keypair you created (`~/.ssh/raspberrypi_key.pub`) (e.g.
  `ssh-ed25519 AAAAC3... anesowa@raspberrypi`)

Always a good idea to upgrade it to the latest and reboot the Raspberry Pi:

```
eulersson@macbook:~ $ ssh -i ~/.ssh/raspberrypi_key anesowa@rpi-master.local
ansesowa@rpi-master:~ $ sudo apt update
ansesowa@rpi-master:~ $ sudo apt full-upgrade
ansesowa@rpi-master:~ $ sudo reboot
```

## Sound & Multiple Bluetooth Speaker Setup

If you have some USB or Bluetooth speakers you want to use this guide explains how to
set them up using `Raspberry Pi OS` (based on `Debian bookworm` at the time of writing).

If you use Raspberry Pi 4 the audio system uses [PipeWire](https://pipewire.org/), for
older versions you should use
[PulseAudio](https://www.freedesktop.org/wiki/Software/PulseAudio/) (you might have to
install it).

To my understanding **PulseAudio** is a higher framework built to manage
[ALSA](https://www.alsa-project.org/wiki/Main_Page) which is the lowest level layer.
Without **PulseAudio** for instance, you wouldn't be able to mix sounds from two
applications to `ALSA`.

However **PulseAudio** can be a bit Frankenstein and **PipeWire** is built on top of
both to manage the sound pipelines better.

What we are interested in this guide is to create a combined audio sink that send the
sound to so it can be played in various sound devices at once.

### Installation

Usually you should have the **PulseAudio** server running by default, check that with
`ps -e | grep pulse` and check if there is the server process. Note that you might have
**PipeWire** running (`pipewire-pulse`).

If not (in the case of older Raspberry Pi devices) you want to install **PulseAudio** as
well as the package that allows **PulseAudio** to setup Bluetooth audio:

```
ansesowa@rpi-master:~ $ sudo apt install pulseaudio pulseaudio-module-bluetooth
```

### Configuration

You will be playing with the various PulseAudio utils such as `pactl`, `paplay`, ...

#### USB Speaker

Plug the USB speaker and you should see it listed to be used as an audio sink:

```
ansesowa@rpi-master:~ $ pactl list sinks short
67      alsa_output.usb-Jieli_Technology_UACDemoV1.0_1120040808090721-01.analog-stereo  PipeWire        s16le 2ch 48000Hz       SUSPENDED
69      alsa_output.platform-bcm2835_audio.stereo-fallback      PipeWire        s16le 2ch 48000Hz       SUSPENDED
```

#### Bluetooth Speaker

Connect your Bluetooth speakers by using `bluetoothctl`. This is an interactive process
which would need to be done manually on each Raspberry Pi. In the following example you
can see how to connect a bluetooth device `JBL GO 2` with MAC ` F8:5C:7D:0F:6D:46`:

```
ansesowa@rpi-master:~ $ bluetoothctl

# Power on and start scanning until you find the JBL GO 2 you are looking for:

[bluetooth]# power on
[bluetooth]# scan on
[NEW] Device F8:5C:7D:0F:6D:46 JBL GO 2

# Scanning can be turned off:

[bluetooth]# scan off
[CHG] Controller DC:A6:32:50:10:F5 Discovering: no
Discovery stopped

# Pair, trust, and connect the device:

[bluetooth]# pair F8:5C:7D:0F:6D:46
Attempting to pair with F8:5C:7D:0F:6D:46
[CHG] Device F8:5C:7D:0F:6D:46 Connected: yes
[CHG] Device F8:5C:7D:0F:6D:46 Bonded: yes
[CHG] Device F8:5C:7D:0F:6D:46 UUIDs: 00001108-0000-1000-8000-00805f9b34fb
[CHG] Device F8:5C:7D:0F:6D:46 UUIDs: 0000110b-0000-1000-8000-00805f9b34fb
[CHG] Device F8:5C:7D:0F:6D:46 UUIDs: 0000110c-0000-1000-8000-00805f9b34fb
[CHG] Device F8:5C:7D:0F:6D:46 UUIDs: 0000110e-0000-1000-8000-00805f9b34fb
[CHG] Device F8:5C:7D:0F:6D:46 UUIDs: 0000111e-0000-1000-8000-00805f9b34fb
[CHG] Device F8:5C:7D:0F:6D:46 ServicesResolved: yes
[CHG] Device F8:5C:7D:0F:6D:46 Paired: yes
Pairing successful

[bluetooth]# trust F8:5C:7D:0F:6D:46
[CHG] Device F8:5C:7D:0F:6D:46 Trusted: yes
Changing F8:5C:7D:0F:6D:46 trust succeeded

[bluetooth]# connect F8:5C:7D:0F:6D:46
Attempting to connect to F8:5C:7D:0F:6D:46
[CHG] Device F8:5C:7D:0F:6D:46 Connected: yes
[NEW] Endpoint /org/bluez/hci0/dev_F8_5C_7D_0F_6D_46/sep1
[NEW] Transport /org/bluez/hci0/dev_F8_5C_7D_0F_6D_46/sep1/fd0
Connection successful
[CHG] Device F8:5C:7D:0F:6D:46 ServicesResolved: yes
[CHG] Transport /org/bluez/hci0/dev_F8_5C_7D_0F_6D_46/sep1/fd0 Volume: 0x003b (59)

[JBL GO 2]# exit
```

If you have problems connecting the Bluetooth speaker check the service's logs:

```
ansesowa@rpi-master:~ $ journalctl -u bluetooth.service
```

For instance you might get:

```
[bluetooth]# connect F8:5C:7D:0F:6D:46
Attempting to connect to F8:5C:7D:0F:6D:46
Failed to connect: org.bluez.Error.Failed br-connection-profile-unavailable
[DEL] Device 6B:53:9D:87:E4:7A 6B-53-9D-87-E4-7A
[bluetooth]# exit
anesowa@rpi-master:~ $ journalctl -u bluetooth.service | tail -n 1
Nov 20 20:54:27 rpi-master bluetoothd[682]: src/service.c:btd_service_connect() a2dp-sink profile connect failed for F8:5C:7D:0F:6D:46: Protocol not available
```

This error happened to me the first time I tried to connect the Bluetooth speaker after
having installed `pulseaudio` and `pulseaudio-module-bluetooth`. It got fixed after
rebooting!

```
ansesowa@rpi-master:~ $ pactl list sinks short
67      alsa_output.usb-Jieli_Technology_UACDemoV1.0_1120040808090721-01.analog-stereo  PipeWire        s16le 2ch 48000Hz       SUSPENDED
69      alsa_output.platform-bcm2835_audio.stereo-fallback      PipeWire        s16le 2ch 48000Hz       SUSPENDED
80      bluez_output.F8_5C_7D_0F_6D_46.1        PipeWire        s16le 2ch 48000Hz       SUSPENDED
86      bluez_output.70_99_1C_51_36_1B.1        PipeWire        s16le 2ch 48000Hz       SUSPENDED
```

Try to play a sound to the new sink:

```
ansesowa@rpi-master:~ $ pactl set-default-sink bluez_output.F8_5C_7D_0F_6D_46.1
ansesowa@rpi-master:~ $ aplay /usr/share/sounds/alsa/Front_Center.wav # ALSA player
ansesowa@rpi-master:~ $ paplay /usr/share/sounds/alsa/Front_center.wav # PulseAudio player
ansesowa@rpi-master:~ $ pw-play /usr/share/sounds/alsa/Front_center.wav # PipeWire player
ansesowa@rpi-master:~ $ speaker-test
```

Get / set default sink (speaker output):

```
pactl get-default-sink
pactl set-default-sink <sink-name>
```

Get / set default source (microphone input):

```
pactl get-default-source
pactl set-default-source <sink-name>
```

##### Reconnecting

Raspberry Pi 4 seemed to reconnect to the speakers upon `rebooting`, but not on
Raspberry Pi 3 B+, which uses an older `bluetoothctl` (5.66 vs 5.55).

If you want to reconnect the speaker after reboot, what worked with JBL GO 2 is to turn
the speaker off and on. Then it autoconnects.

#### Combining Sinks

To be able to play a sound to two or more speakers you can create a combined sink:

```
# Combine all available sinks:

ansesowa@rpi-master:~ $ pactl load-module module-combine-sink
536870913

# NOTE: You can pass arguments to the module-combine-sink arguments to select what
#   devices you want to connect. To see the available sinks use `pactl list sinks short`.
#
#   pactl load-module module-combine-sink sink_name=combined-sink sink_properties=device.description=Combined slaves=bluez_output.F8_5C_7D_0F_6D_46.1,bluez_output.70_99_1C_51_36_1B.1,alsa_output.usb-Jieli_Technology_UACDemoV1.0_1120040808090721-01.analog-stereo
#
```

Now check if it has been created:

```
ansesowa@rpi-master:~ $ pactl list sinks short
67      alsa_output.usb-Jieli_Technology_UACDemoV1.0_1120040808090721-01.analog-stereo  PipeWire        s16le 2ch 48000Hz       SUSPENDED
69      alsa_output.platform-bcm2835_audio.stereo-fallback      PipeWire        s16le 2ch 48000Hz       SUSPENDED
80      bluez_output.F8_5C_7D_0F_6D_46.1        PipeWire        s16le 2ch 48000Hz       SUSPENDED
86      bluez_output.70_99_1C_51_36_1B.1        PipeWire        s16le 2ch 48000Hz       SUSPENDED
131     combined-sink                           PipeWire        float32le 2ch 48000Hz   SUSPENDED
```

Select it to be the default sink:

```
ansesowa@rpi-master:~ $ pactl set-default-sink combined-sink
```

To play sound to it:

```
ansesowa@rpi-master:~ $ speaker-test
```

#### Persisting Configuration

If you restart the default sink might not be `combined-sink` anymore. You need to
persist that sink.

Depending on whether you have **PipeWire** available or not (in which case you would use
**PulseAudio** directly) the steps change a bit.

You can check if **PipeWire** is installed by:

```
$ apt list --installed | grep pipewire
libpipewire-0.3-0/stable,now 0.3.65-3+rpt2 arm64 [installed,automatic]
libpipewire-0.3-common/stable,stable,now 0.3.65-3+rpt2 all [installed,automatic]
libpipewire-0.3-modules/stable,now 0.3.65-3+rpt2 arm64 [installed,automatic]
pipewire-bin/stable,now 0.3.65-3+rpt2 arm64 [installed,automatic]
pipewire-libcamera/stable,now 0.3.65-3+rpt2 arm64 [installed,automatic]
pipewire-pulse/stable,now 0.3.65-3+rpt2 arm64 [installed,automatic]
pipewire/stable,now 0.3.65-3+rpt2 arm64 [installed,automatic]
```

##### If PipeWire Available

Create a `~/.config/pipewire/pipewire.conf.d/<name>.conf` so **PipeWire** gets it by
default.

```
$ mkdir -p ~/.config/pipewire/pipewire.conf.d
$ touch ~/.config/pipewire/pipewire.conf.d/add-combined-sink.conf
```

Now use your editor to edit `add-combined-sink.conf`:

```
context.exec = [
    { path = "pactl" args = "load-module module-combine-sink" }
    { path = "pactl" args = "set-default-sink combined" }
]
```

To enable audio I/O from the Docker container into the host (Raspberry Pi) we need to
enable PulseAudio's `module-native-protocol-tcp`. To do that everytime we boot the
Raspberry Pi create another config `~/.config/pipewire/pipewire.conf.d/enable-tcp.conf`:

```
# Sources:
#
#   https://stackoverflow.com/a/39780130/2649699
#   https://gist.github.com/janvda/e877ee01686697ceaaabae0f3f87da9c
#   https://github.com/mviereck/x11docker/wiki/Container-sound:-ALSA-or-Pulseaudio
#
context.exec = [
    { path = "pactl" args = "load-module module-native-protocol-tcp" }
]
```

##### If PipeWire Not Available

Then `default.pa` (PulseAudio Sound Server Startup Script) is what needs to be edited.

We can drop files in `/etc/pulse/default.pa.d/` and they will be processed so let's do
that:

Create `/etc/pulse/default.pa.d/combine-sinks-and-set-default.pa` with these contents:

```
load-module module-combine-sink
set-default-sink combined
```

Create `/etc/pulse/default.pa.d/enable-tcp.pa` with these contents:

```
load-module module-native-protocol-tcp
```

Now restart the pulse server:

```
systemctl --user restart pulseaudio.service
```

#### Persisting Audio Volume Levels

First we need to disable a feature called **flat volumes** that will mess with the rest
of volumes when you change a particular one.

> **flat-volumes** scales the device-volume with the volume of the "loudest"
> application. For example, raising the VoIP call volume will raise the hardware volume
> and adjust the music-player volume so it stays where it was, without having to lower
> the volume of the music-player manually. Defaults to yes upstream, but to no within
> Arch. Note: The default behavior upstream can sometimes be confusing and some
> applications, unaware of this feature, can set their volume to 100% at startup,
> potentially blowing your speakers or your ears. This is why Arch defaults to the
> classic (ALSA) behavior by setting this to no.

```
...
flat-volumes = no
...
```

Then restart the service `systemctl --user restart pulseaudio.service`.

You can read the current audio volume level on each individual speaker as follows:

```
$ pactl get-sink-volume bluez_output.F8_5C_7D_0F_6D_46.1
Volume: front-left: 30446 /  46% / -19.98 dB,   front-right: 30446 /  46% / -19.98 dB
        balance 0.00
```

As you can see it is at `46%` (value of `30446`). The `100%` is `65536`. Let's change it
to the maximum (100%):

```
$ pactl set-sink-volume bluez_output.F8_5C_7D_0F_6D_46.1 65536
```

Do this with the rest of individual speakers:

```
$ pactl set-sink-volume alsa_output.usb-Jieli_Technology_UACDemoV1.0_1120040808090721-01.analog-stereo 65536
$ pactl set-sink-volume bluez_output.70_99_1C_51_36_1B.1 65536
```

Do it with the combined sink too if you want:

```
$ pactl set-sink-volume combined-sink 65536
```

If you reboot, even if the bluetooth speaker disconnects it seems to retain the volume
level set with the `set-sink-volume` command.

## Development Workflow

### macOS & Docker Container Sound

The apps are containerized so we don't have to depend on the system versions of the
upcoming Raspberry Pi OS updates.

If you are developing on a macOS you might find trouble accessing the host microphone
and audio playback device.

I personally use **Rancher Desktop**'s docker daemon, which runs on a linux VM. If I
were on linux I would simply bind the device with `--device /dev/snd:/dev/snd`.

To have a corss-platform solution that also doen't involve a PulseAudio service on the
container is connecting the container as a client to a PulseAudio server running at the
host.

```
eulersson@macbook:~ $ brew install pulseaudio
eulersson@macbook:~ $ brew services start pulseaudio
eulersson@macbook:~ $ paplay sample.wav
```

Open `/usr/local/Cellar/pulseaudio/14.2_1/etc/pulse/default.pa` and uncomment:

```
load-module module-native-protocol-tcp
```

Restart the service with `brew services restart pulseaudio`.

Then from the container you can play a sound with `paplay`:

```
eulersson@macbook:~/Devel/anesowa/sound-detector $ docker build -t anesowa/sound-detector:1.0.0 .
eulersson@macbook:~/Devel/anesowa/sound-detector $ docker run --rm -it \
  -e PULSE_SERVER=host.docker.internal \
  -v $HOME/.config/pulse/cookie:/root/.config/pulse/cookie \
  -v $HOME/Devel/anesowa/sample.wav:/sample.wav \
  anesowa/sound-detector:1.0.0 paplay /sample.wav

# NOTE: The host.docker.internal would not resolve in the Raspberry Pi, for that you
# would need to pass the flag `--add-host="host.docker.internal:host-gateway"`
```

You should have heard some sound coming from the container to the Raspberry Pi and then
into the USB or Bluetooth speaker(s)!

Sources:

- https://stackoverflow.com/a/40139001
- https://stackoverflow.com/a/39780130/2649699
- https://gist.github.com/janvda/e877ee01686697ceaaabae0f3f87da9c
- https://github.com/mviereck/x11docker/wiki/Container-sound:-ALSA-or-Pulseaudio

### Iterative Development

During my development from the macOS

Syncing the changes manually with `rsync`:

```
eulersson@macbook:~ $ rsync \
  -e "ssh -i ~/.ssh/raspberrypi_key.pub" -azhP \
  --exclude "sound-player/build/" --exclude ".git/" --exclude "*.cache*" \
  . ansesowa@rpi-master.local:/home/user/anesowa
```

Then running the corresponding `docker run` volume-binding the project folder:

```
ansesowa@rpi-master:~/anesowa/sound-detector $ docker run ... -v $(pwd):/anesowa/sound-detector ...
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
ansesowa@rpi-master:~ $ uudo apt update
ansesowa@rpi-master:~ $ sudo apt upgrade
ansesowa@rpi-master:~ $ curl https://repos.influxdata.com/influxdata-archive.key | gpg --dearmor | sudo tee /usr/share/keyrings/influxdb-archive-keyring.gpg >/dev/null
ansesowa@rpi-master:~ $ echo "deb [signed-by=/usr/share/keyrings/influxdb-archive-keyring.gpg] https://repos.influxdata.com/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
ansesowa@rpi-master:~ $ sudo apt install influxdb2
ansesowa@rpi-master:~ $ sudo systemctl unmask influxdb
ansesowa@rpi-master:~ $ sudo systemctl enable influxdb
ansesowa@rpi-master:~ $ sudo systemctl start influxdb
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
ansesowa@rpi-master:~ $ influx setup \
  --username anesowa \
  --password ">R7#$gjf>2@dLXUU<" \
  --token XwSAJxRKHFkFL9wLiA4pPrDeXed
  --org anesowa \
  --bucket anesowa \
  --force

# Create an All Access API Token to use when creating resources on the database.
ansesowa@rpi-master:~ $ influx auth create \
  --all-access \
  --host http://localhost:8086 \
  --org anesowa \
  --token XwSAJxRKHFkFL9wLiA4pPrDeXed
ID                      Description     Token                                                                                           User Name       User ID                 Permissions
0c0d6b05a3a6d000                        MkNsrWGwIpZEZvyRGK49-ftUgqoQCmY4rmisobotxxPr_M_Cx_IBxjge_KgOQUswdQr2tmFjzDLmRetkfg0qcg==        supermaster          0c0d68543ca6d000        [read:orgs/8e706e7c04613c15/authorizations write:orgs/8e706e7c04613c15/authorizations read:orgs/8e706e7c04613c15/buckets write:orgs/8e706e7c04613c15/buckets read:orgs/8e706e7c04613c15/dashboards write:orgs/8e706e7c04613c15/dashboards read:/orgs/8e706e7c04613c15 read:orgs/8e706e7c04613c15/sources write:orgs/8e706e7c04613c15/sources read:orgs/8e706e7c04613c15/tasks write:orgs/8e706e7c04613c15/tasks read:orgs/8e706e7c04613c15/telegrafs write:orgs/8e706e7c04613c15/telegrafs read:/users/0c0d68543ca6d000 write:/users/0c0d68543ca6d000 read:orgs/8e706e7c04613c15/variables write:orgs/8e706e7c04613c15/variables read:orgs/8e706e7c04613c15/scrapers write:orgs/8e706e7c04613c15/scrapers read:orgs/8e706e7c04613c15/secrets write:orgs/8e706e7c04613c15/secrets read:orgs/8e706e7c04613c15/labels write:orgs/8e706e7c04613c15/labels read:orgs/8e706e7c04613c15/views write:orgs/8e706e7c04613c15/views read:orgs/8e706e7c04613c15/documents write:orgs/8e706e7c04613c15/documents read:orgs/8e706e7c04613c15/notificationRules write:orgs/8e706e7c04613c15/notificationRules read:orgs/8e706e7c04613c15/notificationEndpoints write:orgs/8e706e7c04613c15/notificationEndpoints read:orgs/8e706e7c04613c15/checks write:orgs/8e706e7c04613c15/checks read:orgs/8e706e7c04613c15/dbrp write:orgs/8e706e7c04613c15/dbrp read:orgs/8e706e7c04613c15/notebooks write:orgs/8e706e7c04613c15/notebooks read:orgs/8e706e7c04613c15/annotations write:orgs/8e706e7c04613c15/annotations read:orgs/8e706e7c04613c15/remotes write:orgs/8e706e7c04613c15/remotes read:orgs/8e706e7c04613c15/replications write:orgs/8e706e7c04613c15/replications]

# Configure connection configuration preset to use.
ansesowa@rpi-master:~ $ influx config create \
  --config-name anesowa \
  --host-url http://localhost:8086 \
  --org anesowa \
  --token MkNsrWGwIpZEZvyRGK49-ftUgqoQCmY4rmisobotxxPr_M_Cx_IBxjge_KgOQUswdQr2tmFjzDLmRetkfg0qcg==
Active  Name            URL                     Org
        anesowa         http://localhost:8086   anesowa

# Generate timestamps with:
ansesowa@rpi-master:~ $ date +%s
1698755458

# Create an entry:
anesowa@rpi-master:~ $ influx write --bucket anesowa --precision s "
acons,sound=high_heel soundfile=\"/path/to/soundfile.wav\" $(date +%s)
"

# Querying:
ansesowa@rpi-master:~ $ influx query 'from(bucket: "anesowa") |> range(start: 2020-10-10T08:00:00Z, stop: 2024-10-10T08:00:00Z) |> filter(fn: (r) => r.\_measurement == "annoying_sounds")'
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

To run the Jupyter Notebook you will need the pip `notebook` package installed, then:

```
jupyter notebook transfer_learning.ipynb
```

### Docker

```
anesowa@rpi-master $ docker build
```

On one shell:

```
anesowa@rpi-master:~ $ pactl load-module module-native-protocol-tcp
```

On the other:

```
anesowa@rpi-master:~ $ docker run --rm -it \
  --add-host="host.docker.internal:host-gateway" \
  -e PULSE_SERVER=host.docker.internal \
  -v $HOME/.config/pulse/cookie:/root/.config/pulse/cookie \
  -v /home/anesowa/sample.wav:/sample.wav \
  anesowa/sound-player:1.0.0 paplay /sample.wav
```

You should have heard some sound coming from the container to the Raspberry Pi and then
into the USB or Bluetooth speaker(s)!

Sources:

- https://stackoverflow.com/a/39780130/2649699
- https://gist.github.com/janvda/e877ee01686697ceaaabae0f3f87da9c
- https://github.com/mviereck/x11docker/wiki/Container-sound:-ALSA-or-Pulseaudio

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
