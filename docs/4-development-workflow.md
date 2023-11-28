# Development Workflow

Depending on the module you are working on the workflow might differ due to the nature
of their language and environment but in any of them you have three choices: (1) using
your workstation, (2) using the Raspberry Pi or (3) using containers on workstation
and/or Raspberry Pi. But all of them will have something in common: to be able to have
the project files available and up to date between the laptop and the Raspberry Pis, and
this is what's discussed in this document.

- [Sound Detector | Development Workflow](/sound-detector#development-workflow)
- [Sound Player | Development Workflow](/sound-player#development-workflow)
- [Playback Distributor | Development Workflow](/playback-distributor#development-workflow)

What I found works well for me is to work with my laptop on a folder that is exported as
an NFS share. The Raspberry Pis then mount that NFS share and get the filesystem. This
made it easier for me than having to synch the files up and down or developing remotely.

After that I would use docker to compile the bits and bobs on both my local laptop as
well as on the Raspberry Pi.

This guide is written considering the NFS host is a macOS machine. If you are on Linux
is way easier since it's not the Apple opinionated stuff, and you should search for the
equivalent commands and syntaxes. If I ever set it up on a Linux I will do it myself.

## Network Volume Approach Overview

A volume could be bound on the host machine (macOS) and Raspberry Pi could mount it with
NFS or SMB. When outside the home LAN then an OpenVPN solution should be set up which is
outside of the scope of this guide.

An alternative to the NFS + OpenVPN would be something like `sshfs`.

PROS:

- Transparent to navigate the mounted remote volume.
- Intellisense (LSP) would work since it resides on the host.

CONS:

- When outside home LAN you need to use VPN to access home LAN resources.

I also evaluated other workflows such as `lsyncd`, `distant` and `distant.nvim` but each
had caveats. I explain why I discarded them in
[Discarded Tools](4-development-workflow#discarded-tools).

## Create a Sharing User & Group on the maOS Host

When mounting NFS shares we want a specific user **remotedevuser** with a specific
**remotedevgroup** group to be used when writing on that share from the client. That
user only needs to exist on the host server. When you mount the share, the client's user
(e.g. _myraspberrypiuser_) will be mapped to _remotedevuser_.

```
# See what user IDs and group IDs exist so you don't pick an existing one:
dscl . -list /Users UniqueID
dscl . -list /Groups PrimaryGroupID

# Create user:
sudo dscl . -create /Users/remotedevuser
sudo dscl . -create /Users/remotedevuser UniqueID 301

# Create group:
sudo dscl . -create /Groups/remotedevgroup
sudo dscl . -create /Groups/remotedevgroup gid 301
sudo dscl . -create /Groups/remotedevgroup PrimaryGroupID 301
sudo dscl . -append /Groups/remotedevgroup GroupMembership eulersson
sudo dscl . -append /Groups/remotedevgroup GroupMembership remotedevuser

# Make the default's remotedevuser primary group be remotedevgroup:
sudo dscl . -create /Users/remotedevuser PrimaryGroupID 301

# Check it's all good:
sudo dscl . -read /Groups/remotedevgroup GroupMembership
GroupMembership: eulersson remotedevuser
```

Sources:

- [Creating a Group Via Users & Groups in Command Line](https://apple.stackexchange.com/a/307186)
- [Why can't I use my newly created user with chown?](https://superuser.com/a/923843)
- [dscl Manual](https://www.unix.com/man-page/osx/1/dscl/)

## Change Project Folder Permissions on the macOS Host

Change the owning group of the `/Users/eulersson/Devel/anesowa` project folder from
`eulersson:eulersson` to `eulersson:remotedevgroup` so all users from **remotedevgroup**
can write, edit, read, delete contents on that folder.

```
# Change the owning group:
sudo chown -R eulersson:remotedevgroup /Users/eulersson/Devel/anesowa

# Ensure group users can write as well as read:
sudo chmod -R g+w /Users/eulersson/Devel/anesowa
```

## Set NFS Share on the macOS Host

We will now export the project folder as an NFS share.

Open up `/etc/exports` on the macOS (which acts as NFS server):

```
/Users/eulersson/Devel/anesowa -network 192.168.1.0 -mask 255.255.255.0 -mapall remotedevuser
```

**NOTE**: `192.168.1.0/24` with your home LAN network range. If you want to be
conservative it could be setup as read-only instead of read-write (by adding the `-ro`
flag), that way if the Raspberry Pi goes nuts and starts corrupting files it would not
affect the host's folder, but I guess it's not critical if the code is versioned with
git.

Check the share is being exported correctly:

```
eulersson@macbook:~ $ sudo nfsd restart

# Should not error. If it's good it does not output.
eulersson@macbook:~ $ sudo nfsd checkexports
```

More information on the `/etc/exports` format on its manual: `man exports`.

If you are out of home use a VPN to connect to your home LAN.

Sources:

- [exports Manual](https://ss64.com/osx/export.html)

## Mounting the NFS Share from the Raspberry Pi

Then on the Raspberry Pi mount the volume (`192.168.1.22` is the IP of the MacBook that
runs the NFS service):

```
sudo mount --types nfs --verbose 192.168.1.22:/Users/eulersson/Devel/anesowa /mnt/nfs/anesowa
```

You can check it mounted correctly with `df -h` or by listing the mounted folder
`ls /mnt/nfs/anesowa`.

When you are done unmount the volume on the client:

```
anesowa@raspberrypi $:~ umount /mnt/nfs/anesowa --lazy
```

And stop exporting it from the server by removing the line we added on `/etc/exports`.

## Discarded Tools for Remote Development

### Discarded Alternative 1: lsyncd

Lsyncd (Live Syncing Daemon) synchronizes local directories with remote targets.

In my case it would be handy to keep the current project folder in sync with the various
Raspberry Pis without having to run `rsync` to all of them or `scp`.

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
