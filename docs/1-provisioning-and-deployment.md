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

- Hostname: `raspberrypi`, `rpi-slave-1`, `rpi-slave-2`, ...
- Set username: `anesowa`.
- Set password.
- Configure wireless LAN.
- Services > Enable SSH: ON.
- Allow public-key authentication only > Set authorized_keys for 'anesowa': copy the
  public key from the keypair you created (`~/.ssh/raspberrypi_key.pub`) (e.g.
  `ssh-ed25519 AAAAC3... anesowa@raspberrypi`).

Always a good idea to upgrade it to the latest and reboot the Raspberry Pi:

```
eulersson@macbook:~ $ ssh -i ~/.ssh/raspberrypi_key anesowa@raspberrypi.local
anesowa@raspberrypi:~ $ sudo apt update
anesowa@raspberrypi:~ $ sudo apt full-upgrade
anesowa@raspberrypi:~ $ sudo reboot
```

## Running the Ansible Playbook

TODO: Do an Ansible playbook for:

- Raspberry Pi Zero
- Rasbperry Pi 3 B
- Raspberry Pi 4

Where you do something like:

```
deploy --type raspberry-pi-zero 192.168.0.55
```

So the Raspberry Pi type should be parametrized.

## Things to Translate Into Ansible Playbook

### Docker

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

### Raspberry Pi < 4

Those Raspberry Pis will need an explicit install of the **PulseAudio** system, because
otherwise they only run on **ALSA**.

```
sudo apt install pulseaudio pulseaudio-module-bluetooth
```
