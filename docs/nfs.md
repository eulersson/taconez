# NFS

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
- [Connecting to an NFS Share on the Raspberry
  Pi](https://pimylifeup.com/raspberry-pi-nfs-client/)
- [The /etc/exports Configuration
  File](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/5/html/deployment_guide/s1-nfs-server-config-exports)

**NOTE**: This guide assumes the master Raspberry Pi runs at `192.168.1.76` in the
network.

**NOTE**: This document is a reference, and you don't need to provision new Raspberry Pis
with those commands since it's done with an Ansible playbook. This is for me to remember
the steps before writing the Ansible Playbook. Read
[Provisioning](/docs/provisioning.md) for more.

## Server Setup

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

## Connecting from a macOS

To connect using _File Explorer > Go > Connect to Server_ (<kbd>⌘</kbd> + <kbd>K</kbd>)
and type in `nfs://neptune.local/mnt/nfs/anesofi`.

## Connecting from Other Raspberry Pi

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
