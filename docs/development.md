# Development Worflow on Raspberry Pi

## Docker & Sound Input/Output

The apps are containerized so we don't have to depend on the system versions of the
upcoming Raspberry Pi OS updates.

If you are developing on a macOS you might find trouble accessing the host microphone
and audio playback device.

I personally use **Rancher Desktop**'s docker daemon, which runs on a linux VM. If I
were on linux I would simply bind the device with `--device /dev/snd:/dev/snd`.

The workaround is to run a **PulseAudio** server on the macOS and make the container
act as a client to it.

```
brew install pulseaudio
brew services start pulseaudio
paplay microphone-sample.wav
```

Open `/usr/local/Cellar/pulseaudio/14.2_1/etc/pulse/default.pa` and uncomment:

```
load-module module-esound-protocol-tcp
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

## Workflow

The workflow to develop should:

Syncing the changes manually with `rsync`:

```
rsync \
  -e "ssh -i ~/.ssh/raspberry_local" -azhP \
  --exclude "sound-player/build/" --exclude ".git/" --exclude "docs/" --exclude "*.cache*" \
  . cooper@neptune.local:/home/cooper/anesofi
```

**PROS**:

- Only the changed files are synced.
- It is secure and encrypted.

**CONS**:

- It's a manual action.
- Only syncs towards a single target machine.

## Discarded Alternative 1: lsyncd

Lsyncd (Live Syncing Daemon) synchronizes local directories with remote targets.

It uses rsync and ssh under the hood every time it detects a filesystem event.

I discarded it because the mantainer himself said it is not reliable on macOS:

> the osx events interface of Lsyncd is generally very outdated, and as far as I know
> unmaintained, unless someone finds willing to do that, and best rewrite it all
> together to use FSEvents insted of that experiment I did back then to directly access
> the internal buffer, I'd advice against using it, or removing it from Lsyncd
> altogether.
>
>   Source: https://github.com/lsyncd/lsyncd/issues/204#issuecomment-1794164518
>

## Discarded Alternative 2: Distant + distant.nvim

- https://distant.dev/
- https://distant.dev/editors/neovim/installation/

Installing a **distant** service on the Raspberry Pi and connecting to it via **Neovim**
is possible. You would be able to browse through the remote files from Neovim and open
them up with your local Neovim resources.

**PROS**:

- Good for connecting to resources that might be outside of the network.
- The communication is efficient and fast because it goes through custom TCP _distant_
  protocol between the _distant_ client and _distant_ server.
- It's encrypted.

**CONS**:

- I couldn't get the language server features working, it seemed to rely on me
  installing all the intellisense tooling on the Raspberry Pi, which I prefer not
  because the compute power of my computer is better than the Pi.
- Code would not reside in my powerful computer.
- I would have to sync from that Raspberry Pi to the rest of them.

## Discarded Alternative 3: Network Volume Binding

We could bind a folder from the Raspberry Pi and make it available in the LAN (local)
network with `NFS` or `SMB` or if I'm outside the local network I could use an encrypted
ssh-filesystem connection `sshfs` or tunnel into my LAN NFS with OpenVPN (that would
make me have to install VPN software on my LAN and client machine).

**PROS**:

- Transparent to navigate the mounted remote volume.
- Intellisense (LSP) would work.

**CONS**:

- The actual code would reside in a Raspberry Pi machine instead of my local filesystem.
- If the Raspberry Pi gets corrupted I lose all the code.
- I would have to sync from that Raspberry Pi to the rest of them.

