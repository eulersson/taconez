## Docker Container Sound

The setup involves having a PulseAudio server running on the host with the TCP protocol
module (`module-native-protocol-unix`) enabled and from the container sending the sound
to that TCP service.

Another possibility would be to use a Unix socket (`module-native-protocol-unix`) but I
did not explore that route because I didn't want to deal with UNIX permissions; the TCP
way uses a cookie mechanism and simply by binding the cookie file and by making the host
service reachable to the container works out well.

I show show to do it on a:

- Raspberry Pi: Required before deploying the Ansible Playbook, otherwise the containers
  that will be deployed won't work. See
  [Provisioning and Deployment](1-provisioning-and-deployment.md).
- macOS: If you want to develop locally away from a Raspberry Pi.

### On Raspberry Pi

Make sure the PulseAudio server process is running on the host and that you have placed
a file on `/etc/pulse/default.pa.d/enable-tcp.pa` and specified to enable the `tcp`
protocol:

```
load-module module-native-protocol-tcp
```

Make sure the correct microphone and speakers are set as default sink and source. Use
`pactl`'s `set-default-sink` and `set-default-source` as explained in the previous
section:
[Default Sink (Sound Output) & Default Source (Sound Input)](2-rpi-sound-setup.md#default-sink-sound-output--default-source-sound-input).

If you want to test that that the PulseAudio on the host is setup correctly try to
record a microphone sample and play it back:

```
anesowa@rpi-master:~/anesowa $ parecord hello.wav
anesowa@rpi-master:~/anesowa $ paplay hello.wav
```

Use the PulseAudio server on the host and the container be its client:

```
anesowa@rpi-master:~/anesowa $ docker build \
  --build-arg="DEBUG=1" \
  -t anesowa/sound-detector:1.0.0 \
  ./sound-detector

# NOTE: The host.docker.internal would not resolve in the Raspberry Pi, for that you
# would need to pass the flag `--add-host`.
anesowa@rpi-master:~/anesowa $ docker run --rm -it \
  --add-host host.docker.internal:host-gateway \
  -e PULSE_SERVER host.docker.internal \
  -v $HOME/.config/pulse/cookie:/root/.config/pulse/cookie \
  anesowa/sound-detector:1.0.0 bash

# From this point on we are inside the container. Try to record and play from it!
root@460b1452b6ba:/anesowa/sound-detector# parecord hello.wav
root@460b1452b6ba:/anesowa/sound-detector# paplay hello.wav

# You can run the app if it went good! Run it like this or simply do not pass anything
# after the `anesowa/sound-detector:1.0.0` argument in the `docker run` command.
root@460b1452b6ba:/anesowa/sound-detector# python sound_detector.py
```

### On macOS

If you are developing on a macOS you might find trouble accessing the host microphone
and audio playback device.

I personally use **Rancher Desktop**'s docker daemon, which runs on a linux VM. If I
were on linux I would simply bind the device with `--device /dev/snd:/dev/snd` but for
the sake of consistency I decided to use the same workflow of reaching the PulseAudio on
the host from the container via TCP.

```
eulersson@macbook:~ $ brew install pulseaudio
eulersson@macbook:~ $ brew services start pulseaudio
eulersson@macbook:~ $ paplay sample.wav
```

Open `/usr/local/Cellar/pulseaudio/14.2_1/etc/pulse/default.pa` and uncomment:

```
load-module module-native-protocol-tcp
```

Make sure the correct microphone and speakers are set as default sink and source. Use
`pactl`'s `set-default-sink` and `set-default-source` as explained in the previous
section:
[Default Sink (Sound Output) & Default Source (Sound Input)](2-rpi-sound-setup.md#default-sink-sound-output--default-source-sound-input).

If you want to test that that the PulseAudio on the host is setup correctly try to
record a microphone sample and play it back:

```
eulersson@macbook:~ $ parecord hello.wav
eulersson@macbook:~ $ paplay hello.wav
```

Now the PulseAudio server is reachable through TCP, so the container can speak to it.

Restart the service with `brew services restart pulseaudio`.

Make sure to configure the `MacBook Pro Speakers` and `MacBook Pro Microphone` as the
default sink and source respectively:

```
# Find out the identifier for the MacBook Pro Speakers sink:
eulersson@macbook:~ $ pactl list sinks
Sink #0
        ...
        Name: 1__2
        Description: MacBook Pro Speakers
        ...
Sink #1
...
Sink #4

# Set it as default sink:
eulersson@macbook:~ $ pactl set-default-sink 1__2

# Find out the identifier for the MacBook Pro Microphone source:
$eulersson@macbook:~ $ pactl list sources
Source #1
Source #2
        ...
        Name: Channel_1.2
        Description: MacBook Pro Microphone
        ...
...
Source #14

# Set it as default source:
eulersson@macbook:~ $ pactl set-default-source Channel_1.2
```

**NOTE**: For some bizarre reason `pactl get-default-sink` or `pactl get-default-source`
do not work on macOS.

Then from the container you can play a sound with `paplay`:

```
eulersson@macbook:~/Devel/anesowa $ docker build \
  -t anesowa/sound-detector:1.0.0 \
  --build-arg DEBUG=1 \
  ./sound-detector

# NOTE: The host.docker.internal would not resolve in the Raspberry Pi, for that you
# would need to pass the flag `--add-host="host.docker.internal:host-gateway"`
eulersson@macbook:~/Devel/anesowa $ docker run --rm -it \
  -e PULSE_SERVER=host.docker.internal \
  -v $HOME/.config/pulse/cookie:/root/.config/pulse/cookie \
  anesowa/sound-detector:1.0.0 bash

# From this point on we are inside the container. Try to record and play from it!
root@460b1452b6ba:/anesowa/sound-detector# apt-get install pulseaudio-utils
root@460b1452b6ba:/anesowa/sound-detector# parecord hello.wav
root@460b1452b6ba:/anesowa/sound-detector# paplay hello.wav

# You can run the app if it went good! Run it like this or simply do not pass anything
# after the `anesowa/sound-detector:1.0.0` argument in the `docker run` command.
root@460b1452b6ba:/anesowa/sound-detector# python sound_detector.py
```

Sources:

- [Using pulseaudio in docker container ](https://gist.github.com/janvda/e877ee01686697ceaaabae0f3f87da9c)
- [Container sound: ALSA or Pulseaudio](https://github.com/mviereck/x11docker/wiki/Container-sound:-ALSA-or-Pulseaudio)
- [How to expose audio from Docker container to a Mac?](https://stackoverflow.com/a/40139001)
- [Run apps using audio in a docker container](https://stackoverflow.com/a/39780130/2649699)
