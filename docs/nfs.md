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

## Server Setup

```
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install nfs-kernel-server -y
sudo mkdir /mnt/nfs/anesofi
sudo chown -R cooper:cooper /mnt/nfs/anesofi
sudo find /mnt/nfs/anesofi/ -type d -exec chmod 755 {} \;
sudo find /mnt/nfs/anesofi/ -type f -exec chmod 644 {} \;
```

```
# TODO: Do not allow anonymous access.
id cooper 
# Output: <cooper-id>
```

```
# File: /etc/exports
/mnt/nfs/anesofi *(rw,all_squash,insecure,async,no_subtree_check,anonuid=<cooper-id>,anongid=<cooper-id>)

# TODO: Do not allow anonymous access. Sould it be the following?
# /mnt/nfs/anesofi 192.168.1.0/24(rw)
```

## Connecting from Other Raspberry Pi

```
sudo apt update
sudo apt full-upgrade
sudo apt install nfs-common
mount -t nfs -o proto=tcp,port=2049 192.168.1.76:/mnt/nfs/anesofi /mnt/nfs/anesofi
# TODO: Check the portion that comes after `76:` and before the ` ` empty space in the above line.
```

## Connecting from macOS & Windows

### Windows

From Windows:

1. To interact with NFS shares on Windows, we need first to enable the NFS client. By
   default, this feature is disabled on Windows installations. To do this, you must
   search for “turn windows features on or off” within Windows and click the “Turn
   Windows features on or off” option that appears
2. Within this menu, search for the “Services for NFS” (1.) folder and click the
   checkbox to enable all available features. Once done, click the “OK” button (2.) to
   finalize the settings. Your windows installation will proceed to set up everything
   that is required to connect with an NFS share.
3. Now open up file explorer, and you should be able to see the “Map network drive”
   option. Click this option to continue the process of connecting your Raspberry Pi’s
   NFS share to your computer.
4. On this screen, you need to enter your Raspberry Pi’s IP address followed by the
   folder we mounted to the NFS Share (1.). For example, with our Raspberry Pi’s IP
   address being “192.168.0.159” and the folder we set up is at “\mnt\nfsshare“. The
   “folder” that we will be “\\192.168.0.159\mnt\nfsshare“. Once entered, click the
   “Finish” button (2.) to finalize the connection.
5. You should now be able to see your shared Raspberry Pi NFS folder under “Network
   Locations” or “Network” on your Windows device.

### macOS

1. Now it’s time to connect to your Raspberry Pi’s NFS Share on MAC OS X, and you will
   have to start by opening up the Finder application.
2. With the “Finder” application open, click “Go” (1.) in the toolbar at the top of the
   screen and then click the “Connect to Server...” (2.) option.
3. Next, you will be required to enter the address that you want to connect to (1.). The
   address that you need to enter into this is a combination of the “nfs:\\” protocol,
   followed by your Raspberry Pi’s IP address. Lastly, it ends with the directory that
   you are trying to access. For example, with the IP “192.168.0.159” and the folder we
   shared on the Pi being “\mnt\nfsshare” the address we would enter is
   “nfs:\\192.168.0.159\mnt\nfsshare“ Once done, click the “Connect” button (2.) to link
   the shared volume.
4. If a connection is successful, you will see a new window that shows you the inside of
   the folder that you shared using the NFS Protocol on your Raspberry Pi.

You can also find the folder again by looking in the “Locations” section in the Finder
sidebar.