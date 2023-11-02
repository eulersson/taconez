# Speakers

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

## Installation

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

## Configuration

### USB Speaker

Plug the USB speaker and you should see it listed to be used as an audio sink:

```
$ pactl list sinks short
67      alsa_output.usb-Jieli_Technology_UACDemoV1.0_1120040808090721-01.analog-stereo  PipeWire        s16le 2ch 48000Hz       SUSPENDED
69      alsa_output.platform-bcm2835_audio.stereo-fallback      PipeWire        s16le 2ch 48000Hz       SUSPENDED
```

### Bluetooth Speaker

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

#### Reconnecting

I realized on Raspberry Pi 4 it reconnects if I `reboot`, but not on Raspberry Pi 3,
which uses an older `bluetoothctl` (5.66 vs 5.55).

If you want to reconnect the speaker after reboot, what I found that works with JBL GO 2
is to turn the speaker off and on. Then it autoconnects.

### Combining Sinks

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

### Persisting Configuration

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

#### If PipeWire Available

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

#### If PipeWire Not Available

Then you must use the `default.pa` (PulseAudio Sound Server Startup Script).

Open up `/etc/pulse/default.pa` with `sudo` and add the following contents in the end:

```
load-module module-combine-sink
set-default-sink combined
```

### Persisting Audio Volume Levels

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