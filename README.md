# anesowa: (A)nnoying (Ne)ighbour (So)nic (Wa)rfare

AI IoT Raspberry Pi powered solution to detect, analyse and react against discomforting
high heel sounds.

## Motivation

My neighbour upstairs decided to walk on high heels. I expressed my discomfort and she
took it as a personal attack, rejecting all kind of mediation. Since I received insults
I decided to use the mirror strategy to see if she realizes how unpleasant it becomes.

## Description

This project is composed of various pieces:

| Module               | Purpose                                                                                                            |
| -------------------- | ------------------------------------------------------------------------------------------------------------------ |
| Sound Detector       | Discriminate and pick up specific sounds using AI.                                                                 |
| Playback Distributor | Route the detected sound and bounce it back.                                                                       |
| Sound Player         | Play any given sound by the distributor.                                                                           |
| Journal              | Visualize the sound occurrences. Useful to have an objective overview. If case gets to lawyers it might be useful. |

## Technology

This is intended to be run in a group of Raspberry Pi

| Tool                 | Purpose                                              | Why (Reason)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| -------------------- | ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| TensorFlow (Python)  | Audio detection                                      | It provides even a higher level API (Keras) that simplifies ML workflows.                                                                                                                                                                                                                                                                                                                                                                                                                              |
| Next.js (JavaScript) | Data visualization webapp.                           | It is a full-stack solution that allows to split a React application between server and client components, allowing you to dispatch the database queries from the server and return a rendered React component with all the data displayed, removing any interaction between the browser and the database. We can also have simple REST-style API endpoints that can be listening to the sound detector and writing to database as well as small endpoints for small controls exposed in the frontend. |
| InfluxDB             | Record storage.                                      | A time-series database seems very appropiate considering the nature of the data (timestamped). Chosen in favour of Prometheus because it supports `string` data types and it's PUSH-based instead of PULL-based. We don't want to lose occurrences!                                                                                                                                                                                                                                                    |
| NFS                  | Sharing a volume with the audio data.                | The database should not get bloated with binary data. Once the audio file is producted, we hash it and store it in the NFS-shared file system.                                                                                                                                                                                                                                                                                                                                                         |
| ZeroMQ               | Communication audio detector <-> playback receivers. | Instead of having to implement an API, since it's only one instruction, it's simpler to use a PUB-SUB pipeline in the fashionn of a queue. The detector places an element and all playback receivers react playing back the sound. I didn't want another centralized service in the master raspberry pi, so a brokerless solution is more appealing.                                                                                                                                                   |
| Docker               | Containerization.                                    | Protect against underlaying operating system components that might get updated and break the app.                                                                                                                                                                                                                                                                                                                                                                                                      |
| Ansible              | Provisioning.                                        | Automates some base configuration installation on new Raspberry Pi hosts, such as the sound setup.                                                                                                                                                                                                                                                                                                                                                                                                     |

## Architecture

![Diagram](anesofi.svg)

Under each folder in this repository you will find more information about the particular
piece.

- [sound-detector](sound-detector)
- [sound-player](sound-player)
- [playback-distributor](playback-distributor)

## Sound & Multiple Bluetooth Speaker Setup

If you have some USB or Bluetooth speakers you want to use this guide explains how to
set them up using `Raspberry Pi OS` (based on `Debian bookworm` at the time).

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
`ps -e | grep pulseaudio` and check if there is the server process.

If not (in the case of older Raspberry Pi devices) you want to install **PulseAudio** as
well as the package that allows **PulseAudio** to setup Bluetooth audio:

```
# Only on older Raspberry Pi
sudo apt update
sudo apt full-upgrade
sudo apt install pulseaudio pulseaudio-module-bluetooth
```

### Configuration

#### USB Speaker

Plug the USB speaker and you should see it listed to be used as an audio sink:

```
$ pactl list sinks short
67      alsa_output.usb-Jieli_Technology_UACDemoV1.0_1120040808090721-01.analog-stereo  PipeWire        s16le 2ch 48000Hz       SUSPENDED
69      alsa_output.platform-bcm2835_audio.stereo-fallback      PipeWire        s16le 2ch 48000Hz       SUSPENDED
```

#### Bluetooth Speaker

Connect your Bluetooth speakers by using `bluetoothctl`.

```
$ bluetoothctl
[bluetooth]# power on
[bluetooth]# scan on
[NEW] Device F8:5C:7D:0F:6D:46 JBL GO 2

[bluetooth]# scan off
[CHG] Controller DC:A6:32:50:10:F5 Discovering: no
Discovery stopped

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

If you have problems connecting the Bluetooth speaker check the logs:

```
journalctl -u bluetooth.service
```

Sometimes the connection failed, but after a reboot it connected well.

Then you can see if the audio sink for that device exists. In the following example you
can see I connected a USB speaker as well as two Bluetooth speakers.

```
$ pactl list sinks short
67      alsa_output.usb-Jieli_Technology_UACDemoV1.0_1120040808090721-01.analog-stereo  PipeWire        s16le 2ch 48000Hz       SUSPENDED
69      alsa_output.platform-bcm2835_audio.stereo-fallback      PipeWire        s16le 2ch 48000Hz       SUSPENDED
80      bluez_output.F8_5C_7D_0F_6D_46.1        PipeWire        s16le 2ch 48000Hz       SUSPENDED
86      bluez_output.70_99_1C_51_36_1B.1        PipeWire        s16le 2ch 48000Hz       SUSPENDED
```

Try to play a sound to the new sink:

```
$ pactl set-default-sink bluez_output.F8_5C_7D_0F_6D_46.1
$ speaker-test
```

##### Reconnecting

I realized on Raspberry Pi 4 it reconnects if I `reboot`, but not on Raspberry Pi 3,
which uses an older `bluetoothctl` (5.66 vs 5.55).

If you want to reconnect the speaker after reboot, what I found that works with JBL GO 2
is to turn the speaker off and on. Then it autoconnects.

#### Combining Sinks

To be able to play a sound to two or more speakers you can create a combined sink:

```
# Combine all available sinks:
$ pactl load-module module-combine-sink
536870913

# NOTE: You can pass arguments to the module-combine-sink arguments to select what
#   devices you want to connect. To see the available sinks use `pactl list sinks short`.
#
#   $ pactl load-module module-combine-sink sink_name=combined-sink sink_properties=device.description=Combined slaves=bluez_output.F8_5C_7D_0F_6D_46.1,bluez_output.70_99_1C_51_36_1B.1,alsa_output.usb-Jieli_Technology_UACDemoV1.0_1120040808090721-01.analog-stereo
#
```

Now check if it has been created:

```
$ pactl list sinks short
67      alsa_output.usb-Jieli_Technology_UACDemoV1.0_1120040808090721-01.analog-stereo  PipeWire        s16le 2ch 48000Hz       SUSPENDED
69      alsa_output.platform-bcm2835_audio.stereo-fallback      PipeWire        s16le 2ch 48000Hz       SUSPENDED
80      bluez_output.F8_5C_7D_0F_6D_46.1        PipeWire        s16le 2ch 48000Hz       SUSPENDED
86      bluez_output.70_99_1C_51_36_1B.1        PipeWire        s16le 2ch 48000Hz       SUSPENDED
131     combined-sink                           PipeWire        float32le 2ch 48000Hz   SUSPENDED
```

Select it to be the default sink:

```
$ pactl set-default-sink bluez_output.F8_5C_7D_0F_6D_46.1
```

To play sound to it:

```
$ speaker-test
$ aplay /usr/share/sounds/alsa/Front_Center.wav
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

Create a ~/.config/pipewire/pipewire.conf.d/<name>.conf so **PipeWire** gets it by
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

##### If PipeWire Not Available

Then you must use the `default.pa` (PulseAudio Sound Server Startup Script).

Open up `/etc/pulse/default.pa` with `sudo` and add the following contents in the end:

```
load-module module-combine-sink
set-default-sink combined
```

#### Persisting Audio Volume Levels

First we need to disable a feature called **flat volumes** that will mess with the rest
of volumes when you change a particular one. What flat volumes aims to fix is keeping
the master system audio aligned with all the speakers, that is: if you change the master
volume to `30%` it would change all the linked speakers to `30%`. I would suggest
turning that feature off by editing `/etc/pulse/daemon.conf` and uncommenting the line
so it ends up like this:

```
...
flat-volumes = no
...
```

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

## Development Workflow

### macOS, Docker & Sound I/O

The apps are containerized so we don't have to depend on the system versions of the
upcoming Raspberry Pi OS updates.

If you are developing on a macOS you might find trouble accessing the host microphone
and audio playback device.

I personally use **Rancher Desktop**'s docker daemon, which runs on a linux VM. If I
were on linux I would simply bind the device with `--device /dev/snd:/dev/snd`.

The workaround is to run a **PulseAudio** server on the macOS and make the container act
as a client to it.

```
brew install pulseaudio
brew services start pulseaudio
paplay microphone-sample.wav
```

Open `/usr/local/Cellar/pulseaudio/14.2_1/etc/pulse/default.pa` and uncomment:

```
load-module module-native-protocol-tcp
```

Restart the service with `brew services restart pulseaudio`.

Then from the container you can play a sound with `paplay`:

```
cd anesowa
docker run --rm -it \
  -e PULSE_SERVER=host.docker.internal  \
  -v $HOME/.config/pulse/cookie:/home/pulseaudio/.config/pulse/cookie \
  -v ./microphone-sample.wav:/microphone-sample.wav \
  --entrypoint paplay \
  jess/pulseaudio /microphone-sample.wav
```

Source:

- [How to expose audio from Docker container to a Mac?](https://stackoverflow.com/a/40139001)

### Iterative Development

The workflow to develop should:

Syncing the changes manually with `rsync`:

```
rsync \
  -e "ssh -i ~/.ssh/raspberry_local" -azhP \
  --exclude "sound-player/build/" --exclude ".git/" --exclude "docs/" --exclude "*.cache*" \
  . cooper@neptune.local:/home/cooper/anesofi
```

Then running the corresponding `docker run` volume-binding the project folder:

```
pi@raspberry1:~/anesowa/sound-detector $ docker run ... -v $(pwd):/anesowa/sound-detector ...
```

PROS:

- Only the changed files are synced.
- It is secure and encrypted.

CONS:

- It's a manual action.
- Only syncs towards a single target machine.

I also evaluated other workflows such as `lsyncd`, `distant` and `distant.nvim` or
simply having a network volume and working on there but each had caveats. I explain why
I discarded them in [Discarded Tools](#discarded-tools).

## Database (InfluxDB)

This project uses **InfluxDB**, a times series database is to be used to log noise
occurrences.

These guides are used as reference:

- [Install InfluxDB on Raspberry Pi](https://docs.influxdata.com/influxdb/v2/install/?t=Raspberry+Pi)
- [InfluxDB Docs | Get started writing data](https://docs.influxdata.com/influxdb/v2/get-started/write)
- [InfluxDB Docs | Get started querying data](https://docs.influxdata.com/influxdb/v2/get-started/query)

**NOTE**: This document is a reference, and you don't need to provision new Raspberry
Pis with those commands since it's done with an Ansible playbook. This is for me to
remember the steps before writing the Ansible Playbook. Read
[Provisioning](/docs/provisioning.md) for more.

### Installation

**NOTE**: This will be done in the `Dockerfile.`.

```
sudo apt update
sudo apt upgrade
curl https://repos.influxdata.com/influxdata-archive.key | gpg --dearmor | sudo tee /usr/share/keyrings/influxdb-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/influxdb-archive-keyring.gpg] https://repos.influxdata.com/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
sudo apt install influxdb2
sudo systemctl unmask influxdb
sudo systemctl enable influxdb
sudo systemctl start influxdb
```

```
# influxdata-archive_compat.key GPG fingerprint:
#     9D53 9D90 D332 8DC7 D6C8 D3B9 D8FF 8E1F 7DF8 B07E
wget -q https://repos.influxdata.com/influxdata-archive_compat.key
echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list

sudo apt update && sudo apt install influxdb2
```

### Configuration

```
$ influx setup \
  --username elohim \
  --password ">R7#$gjf>2@dLXUU<" \
  --token XwSAJxRKHFkFL9wLiA4pPrDeXed
  --org anesofi \
  --bucket anesofi \
  --force

$ influx auth create \
  --all-access \
  --host http://localhost:8086 \
  --org anesofi \
  --token XwSAJxRKHFkFL9wLiA4pPrDeXed
  ID                      Description     Token                                                                                           User Name       User ID                 Permissions
0c0d6b05a3a6d000                        MkNsrWGwIpZEZvyRGK49-ftUgqoQCmY4rmisobotxxPr_M_Cx_IBxjge_KgOQUswdQr2tmFjzDLmRetkfg0qcg==        elohim          0c0d68543ca6d000        [read:orgs/8e706e7c04613c15/authorizations write:orgs/8e706e7c04613c15/authorizations read:orgs/8e706e7c04613c15/buckets write:orgs/8e706e7c04613c15/buckets read:orgs/8e706e7c04613c15/dashboards write:orgs/8e706e7c04613c15/dashboards read:/orgs/8e706e7c04613c15 read:orgs/8e706e7c04613c15/sources write:orgs/8e706e7c04613c15/sources read:orgs/8e706e7c04613c15/tasks write:orgs/8e706e7c04613c15/tasks read:orgs/8e706e7c04613c15/telegrafs write:orgs/8e706e7c04613c15/telegrafs read:/users/0c0d68543ca6d000 write:/users/0c0d68543ca6d000 read:orgs/8e706e7c04613c15/variables write:orgs/8e706e7c04613c15/variables read:orgs/8e706e7c04613c15/scrapers write:orgs/8e706e7c04613c15/scrapers read:orgs/8e706e7c04613c15/secrets write:orgs/8e706e7c04613c15/secrets read:orgs/8e706e7c04613c15/labels write:orgs/8e706e7c04613c15/labels read:orgs/8e706e7c04613c15/views write:orgs/8e706e7c04613c15/views read:orgs/8e706e7c04613c15/documents write:orgs/8e706e7c04613c15/documents read:orgs/8e706e7c04613c15/notificationRules write:orgs/8e706e7c04613c15/notificationRules read:orgs/8e706e7c04613c15/notificationEndpoints write:orgs/8e706e7c04613c15/notificationEndpoints read:orgs/8e706e7c04613c15/checks write:orgs/8e706e7c04613c15/checks read:orgs/8e706e7c04613c15/dbrp write:orgs/8e706e7c04613c15/dbrp read:orgs/8e706e7c04613c15/notebooks write:orgs/8e706e7c04613c15/notebooks read:orgs/8e706e7c04613c15/annotations write:orgs/8e706e7c04613c15/annotations read:orgs/8e706e7c04613c15/remotes write:orgs/8e706e7c04613c15/remotes read:orgs/8e706e7c04613c15/replications write:orgs/8e706e7c04613c15/replications]

$ influx config create \
  --config-name get-started \
  --host-url http://localhost:8086 \
  --org anesofi \
  --token MkNsrWGwIpZEZvyRGK49-ftUgqoQCmY4rmisobotxxPr_M_Cx_IBxjge_KgOQUswdQr2tmFjzDLmRetkfg0qcg==
Active  Name            URL                     Org
        get-started     http://localhost:8086   anesofi

$ influx bucket create --name get-started
ID                      Name            Retention       Shard group duration    Organization ID         Schema Type
a1bc7a05ece4216a        get-started     infinite        168h0m0s                8e706e7c04613c15        implicit

influx write \
  --bucket get-started \
  --precision s "
home,room=Living\ Room temp=21.1,hum=35.9,co=0i 1641024000
home,room=Kitchen temp=21.0,hum=35.9,co=0i 1641024000
home,room=Living\ Room temp=21.4,hum=35.9,co=0i 1641027600
home,room=Kitchen temp=23.0,hum=36.2,co=0i 1641027600
home,room=Living\ Room temp=21.8,hum=36.0,co=0i 1641031200
home,room=Kitchen temp=22.7,hum=36.1,co=0i 1641031200
home,room=Living\ Room temp=22.2,hum=36.0,co=0i 1641034800
home,room=Kitchen temp=22.4,hum=36.0,co=0i 1641034800
home,room=Living\ Room temp=22.2,hum=35.9,co=0i 1641038400
home,room=Kitchen temp=22.5,hum=36.0,co=0i 1641038400
home,room=Living\ Room temp=22.4,hum=36.0,co=0i 1641042000
home,room=Kitchen temp=22.8,hum=36.5,co=1i 1641042000
home,room=Living\ Room temp=22.3,hum=36.1,co=0i 1641045600
home,room=Kitchen temp=22.8,hum=36.3,co=1i 1641045600
home,room=Living\ Room temp=22.3,hum=36.1,co=1i 1641049200
home,room=Kitchen temp=22.7,hum=36.2,co=3i 1641049200
home,room=Living\ Room temp=22.4,hum=36.0,co=4i 1641052800
home,room=Kitchen temp=22.4,hum=36.0,co=7i 1641052800
home,room=Living\ Room temp=22.6,hum=35.9,co=5i 1641056400
home,room=Kitchen temp=22.7,hum=36.0,co=9i 1641056400
home,room=Living\ Room temp=22.8,hum=36.2,co=9i 1641060000
home,room=Kitchen temp=23.3,hum=36.9,co=18i 1641060000
home,room=Living\ Room temp=22.5,hum=36.3,co=14i 1641063600
home,room=Kitchen temp=23.1,hum=36.6,co=22i 1641063600
home,room=Living\ Room temp=22.2,hum=36.4,co=17i 1641067200
home,room=Kitchen temp=22.7,hum=36.5,co=26i 1641067200
"
```

Generate timestamps with:

```
$ date +%s
1698755458

cooper@neptune:~ $ influx write --bucket get-started --precision s "
tacons,room=neus soroll=\"/path/to/file.wav\" $(date +%s)
"
```

Using the Python client is easy:

```
import influxdb_client
from influxdb_client.client.write_api import SYNCHRONOUS

client = influxdb_client.InfluxDBClient(
url="http://localhost:8086",
org="anesofi",
token="MkNsrWGwIpZEZvyRGK49-ftUgqoQCmY4rmisobotxxPr_M_Cx_IBxjge_KgOQUswdQr2tmFjzDLmRetkfg0qcg==",
)

write_api = client.write_api(write_options=SYNCHRONOUS)
p = influxdb_client.Point("tacons").tag("room", "tete").field("soroll", "/to/file2.wav")
write_api.write(bucket="get-started", org="anesofi", record=p)
```

Querying from the CLI:

```
(env) cooper@neptune:~ $ influx query 'from(bucket: "get-started") |> range(start: 2020-10-10T08:00:00Z, stop: 2024-10-10T08:00:00Z) |> filter(fn: (r) => r.\_measurement == "tacons")'
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

## File Sharing (NFS)

This project uses **NFS** for synchronizing the audio detections so they can be replayed
in all the Raspberry Pis.

The master Raspberry Pi should set up an NFS share mounted on `/mnt/nfs/anesofi` so that
all slaves can connect to it.

Considerations:

- Only allow connecting within the local network.
- Only allow the operating user of the stack (in my case `cooper`) to connect to it.
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
sudo mkdir -p /mnt/nfs/anesofi
sudo chown -R cooper:cooper /mnt/nfs/anesofi
sudo find /mnt/nfs/anesofi/ -type d -exec chmod 755 {} \;
sudo find /mnt/nfs/anesofi/ -type f -exec chmod 644 {} \;

```

Get the user that will be used on anonymous users.

```
# TODO: Do not allow anonymous access.
id cooper
# Output: <cooper-id>
```

Open file `/etc/exports` and set this line, replacing `192.168.1/24` with your local
network CIDR. This determines from where connections will be accepted:

```
/mnt/nfs/anesofi 192.168.1.0/24(rw,all_squash,insecure,no_subtree_check,anonuid=1000,anongid=1000)
```

- `insecure` is needed otherwise from macOS I cannot connect from macOS.

Export the changes:

```
sudo exportfs -ra
```

### Connecting from a macOS

To connect using _File Explorer > Go > Connect to Server_ (<kbd>⌘</kbd> + <kbd>K</kbd>)
and type in `nfs://neptune.local/mnt/nfs/anesofi`.

### Connecting from Other Raspberry Pi

If nfs-common is not installed, install it (it usually is installed by default).

```
sudo apt update
sudo apt full-upgrade
sudo apt install nfs-common
```

Then create a folder and mount the network volume to that folder:

```
sudo mkdir -p /mnt/nfs/anesofi
sudo chmod 755 /mnt/nfs/anesofi
sudo mount -t nfs neptune.local:/mnt/nfs/anesofi /mnt/nfs/anesofi
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
cooper@neptune $ docker build
```

```
cooper@neptune $ read LOWERPORT UPPERPORT < /proc/sys/net/ipv4/ip_local_port_range
cooper@neptune $ while : ; do   PULSE_PORT="`shuf -i $LOWERPORT-$UPPERPORT -n 1`";   ss -lpn | grep -q ":$PULSE_PORT " || break; done
cooper@neptune $ echo $PULSE_PORT
46412
cooper@neptune $ ip -4 -o a | grep docker0 | awk '{print $4}'
172.17.0.1/16
```

On one shell:

```
cooper@neptune:~ $ pactl load-module module-native-protocol-tcp port=46412 auth-ip-acl=172.17.0.1/16
```

On the other:

```
docker run --rm -it -e PULSE_SERVER=tcp:172.17.0.1:46412 \
  -v /home/cooper/anesowa/microphone-sample.wav:/sample.wav \
  anesowa/sound-detector:1.0.0 bash
(inside docker) $  root@a40e6334361f:/anesowa/sound-detector# paplay /sample.wav
(now it sounds on the speaker of the host!)
```

TODO: Move to config file so it runs at startup.

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
pip install --upgrade pip \
 && pip install --upgrade keyrings.alt \ # TODO: Needed?
 && pip install poetry \
 && poetry config virtualenvs.create false \
 && poetry install --no-interaction
```

Now to install the dependencies on Raspberry Pi:

```
# Avoid hanging by disabling the keyring backend.
#
#   https://stackoverflow.com/a/60804443
#
export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring
poetry install
```

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
