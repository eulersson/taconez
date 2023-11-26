# Provisioning

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
anesowa@rpi-master:~ $ sudo apt update
anesowa@rpi-master:~ $ sudo apt full-upgrade
anesowa@rpi-master:~ $ sudo reboot
```

## Running the Ansible Playbook

TBD.
