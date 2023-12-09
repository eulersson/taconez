# Raspberry Pi Sound & Multiple Bluetooth Speaker Setup

If you have some USB or Bluetooth speakers you want to use this guide explains how to
set them up using **Raspberry Pi OS** (based on **Debian bookworm** at the time of
writing).

To my understanding **PulseAudio** is a higher framework built to manage
[ALSA](https://www.alsa-project.org/wiki/Main_Page) which is the lowest level layer.
Without **PulseAudio** for instance, you wouldn't be able to mix sounds from two
applications to ALSA.

However PulseAudio can be a bit Frankenstein and PipeWire is built on top of both to
manage the sound pipelines better. Many users want PulseAudio out of the map but I don't
for now because it allows me two features I don't know how to migrate: (1) Combining
sinks to play simultaneous sound on various speakers or (2) easily setup Bluetooth
sound.

This guide explains how to setup Bluetooth devices and combine various of them to create
a speaker group.

Since our app will run on Docker containers that will use
[PyAudio](https://people.csail.mit.edu/hubert/pyaudio/)
([PortAudio](https://people.csail.mit.edu/hubert/pyaudio/)'s Python bindings) to
interact with the microphone and speakers we will have a bit of a challenge depending on
whether the host running the container is Raspberry Pi OS or macOS. This is explained in
[Docker Container Sound](3-docker-container-sound.md).

### Dependencies

Usually you should have the **PulseAudio** server running by default, check that with
`ps -e | grep pulse` and check if there is the server process. Note that you might have
**PipeWire** running (`pipewire-pulse`).

If not (in the case of older Raspberry Pi devices) you want to install **PulseAudio** as
well as the package that allows **PulseAudio** to setup Bluetooth audio:

```
anesowa@raspberrypi:~ $ sudo apt install pulseaudio pulseaudio-module-bluetooth
```

You will be playing with the various PulseAudio utils such as `pactl`, `paplay`, ... so
make sure the `pulseaudio-utils` are installed, which should be:

```
anesowa@raspberrypi:~ $ sudo apt install pulseaudio-utils
```

### USB Speaker

Plug the USB speaker and you should see it listed to be used as an audio sink:

```
anesowa@raspberrypi:~ $ pactl list sinks short
67      alsa_output.usb-Jieli_Technology_UACDemoV1.0_1120040808090721-01.analog-stereo  PipeWire        s16le 2ch 48000Hz       SUSPENDED
69      alsa_output.platform-bcm2835_audio.stereo-fallback      PipeWire        s16le 2ch 48000Hz       SUSPENDED
```

### Bluetooth Speaker

Connect your Bluetooth speakers by using `bluetoothctl`. This is an interactive process
which would need to be done manually on each Raspberry Pi. In the following example you
can see how to connect a bluetooth device `JBL GO 2` with MAC ` F8:5C:7D:0F:6D:46`:

```
anesowa@raspberrypi:~ $ bluetoothctl

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
anesowa@raspberrypi:~ $ journalctl -u bluetooth.service
```

For instance you might get:

```
[bluetooth]# connect F8:5C:7D:0F:6D:46
Attempting to connect to F8:5C:7D:0F:6D:46
Failed to connect: org.bluez.Error.Failed br-connection-profile-unavailable
[DEL] Device 6B:53:9D:87:E4:7A 6B-53-9D-87-E4-7A
[bluetooth]# exit
anesowa@raspberrypi:~ $ journalctl -u bluetooth.service | tail -n 1
Nov 20 20:54:27 raspberrypi bluetoothd[682]: src/service.c:btd_service_connect() a2dp-sink profile connect failed for F8:5C:7D:0F:6D:46: Protocol not available
```

This error happened to me the first time I tried to connect the Bluetooth speaker after
having installed `pulseaudio` and `pulseaudio-module-bluetooth`. It got fixed after
rebooting!

```
anesowa@raspberrypi:~ $ pactl list sinks short
67      alsa_output.usb-Jieli_Technology_UACDemoV1.0_1120040808090721-01.analog-stereo  PipeWire        s16le 2ch 48000Hz       SUSPENDED
69      alsa_output.platform-bcm2835_audio.stereo-fallback      PipeWire        s16le 2ch 48000Hz       SUSPENDED
80      bluez_output.F8_5C_7D_0F_6D_46.1        PipeWire        s16le 2ch 48000Hz       SUSPENDED
86      bluez_output.70_99_1C_51_36_1B.1        PipeWire        s16le 2ch 48000Hz       SUSPENDED
```

Try to play a sound to the new sink:

```
anesowa@raspberrypi:~ $ pactl set-default-sink bluez_output.F8_5C_7D_0F_6D_46.1
anesowa@raspberrypi:~ $ aplay /usr/share/sounds/alsa/Front_Center.wav # ALSA player
anesowa@raspberrypi:~ $ paplay /usr/share/sounds/alsa/Front_center.wav # PulseAudio player
anesowa@raspberrypi:~ $ pw-play /usr/share/sounds/alsa/Front_center.wav # PipeWire player
anesowa@raspberrypi:~ $ speaker-test
```

### Default Sink (Sound Output) & Default Source (Sound Input)

Get sinks and get / set default sink (speaker output):

```
pactl list sinks short # Omit `short` for a more detailed output.

anesowa@raspberrypi:~ $ pactl get-default-sink
anesowa@raspberrypi:~ $ pactl set-default-sink <sink-name>
```

Get / set default source (microphone input):

```
pactl list sources short # Omit `short` for a more detailed output.

anesowa@raspberrypi:~ $ pactl get-default-source
anesowa@raspberrypi:~ $ pactl set-default-source <sink-name>
```

**NOTE**: Raspberry Pi 4 seemed to reconnect to the speakers upon rebooting, but not on
Raspberry Pi 3 B+, which uses an older `bluetoothctl` (5.66 vs 5.55).

If you want to reconnect the speaker after reboot, what worked with JBL GO 2 is to turn
the speaker off and on. Then it autoconnects.

### Combining Sinks

To be able to play a sound to two or more speakers you can create a combined sink:

```
# Combine all available sinks:

anesowa@raspberrypi:~ $ pactl load-module module-combine-sink
536870913

# Now if you wished to unload that module: `pactl unload-module 536870913`.

# NOTE: You can pass arguments to the module-combine-sink arguments to select what
#   devices you want to connect. To see the available sinks use `pactl list sinks short`.
#
#   pactl load-module module-combine-sink sink_name=combined-sink sink_properties=device.description=Combined slaves=bluez_output.F8_5C_7D_0F_6D_46.1,bluez_output.70_99_1C_51_36_1B.1,alsa_output.usb-Jieli_Technology_UACDemoV1.0_1120040808090721-01.analog-stereo
#
```

Now check if it has been created:

```
anesowa@raspberrypi:~ $ pactl list sinks short
67      alsa_output.usb-Jieli_Technology_UACDemoV1.0_1120040808090721-01.analog-stereo  PipeWire        s16le 2ch 48000Hz       SUSPENDED
69      alsa_output.platform-bcm2835_audio.stereo-fallback      PipeWire        s16le 2ch 48000Hz       SUSPENDED
80      bluez_output.F8_5C_7D_0F_6D_46.1        PipeWire        s16le 2ch 48000Hz       SUSPENDED
86      bluez_output.70_99_1C_51_36_1B.1        PipeWire        s16le 2ch 48000Hz       SUSPENDED
131     combined-sink                           PipeWire        float32le 2ch 48000Hz   SUSPENDED
```

Select it to be the default sink:

```
anesowa@raspberrypi:~ $ pactl set-default-sink combined-sink
```

To play sound to it:

```
anesowa@raspberrypi:~ $ speaker-test
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

#### If PipeWire Not Available

`default.pa` (PulseAudio Sound Server Startup Script) is what needs to be edited.

We can drop files in `/etc/pulse/default.pa.d/` and they will be processed always, even
if we reboot.

Create `/etc/pulse/default.pa.d/combine-sinks-and-set-default.pa` with these contents:

```
load-module module-combine-sink
set-default-sink combined
```

To enable audio I/O from the Docker container into the host (Raspberry Pi) we need to
enable PulseAudio's `module-native-protocol-tcp`. To do that everytime we boot the
Raspberry Pi create `/etc/pulse/default.pa.d/enable-tcp.pa` with these contents:

```
load-module module-native-protocol-tcp
```

Now restart the pulse server:

```
systemctl --user restart pulseaudio.service
```

#### If PipeWire Available

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

Create another config `~/.config/pipewire/pipewire.conf.d/enable-tcp.conf`:

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

### Persisting Audio Volume Levels

First we need to disable a feature called **flat volumes** on the PulseAudio daemon
(`/etc/pulse/daemon.conf`) that will mess with the rest of volumes when you change a
particular one.

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

```
$ pactl set-sink-volume bluez_output.F8_5C_7D_0F_6D_46.1 100%
```

Do this with the rest of individual speakers:

```
$ pactl set-sink-volume alsa_output.usb-Jieli_Technology_UACDemoV1.0_1120040808090721-01.analog-stereo 100%
$ pactl set-sink-volume bluez_output.70_99_1C_51_36_1B.1 100%
```

Do it with the combined sink too if you want:

```
$ pactl set-sink-volume combined-sink 100%
```

If you reboot, even if the bluetooth speaker disconnects it seems to retain the volume
level set with the `set-sink-volume` command.
