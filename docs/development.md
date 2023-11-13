## Development Worflow on Raspberry Pi

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

### Discarded Alternative Method 1: lsyncd

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

### Discarded Alternative Method 2: Distant + distant.nvim

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

### Discarded Alternative Method 3: Network Volume Binding

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
