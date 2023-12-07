# Provisioning and Deployment

Sources:

- https://www.digitalocean.com/community/tutorials/how-to-use-ansible-to-install-and-set-up-docker-on-ubuntu-20-04
- https://github.com/ansible/ansible-examples
- https://docs.ansible.com/ansible/2.8/user_guide/playbooks_tags.html
- https://docs.ansible.com/ansible/2.8/user_guide/playbooks_reuse_roles.html
- https://docs.ansible.com/ansible/2.8/user_guide/playbooks_reuse_includes.html
- https://docs.ansible.com/ansible/2.8/tips_tricks/sample_setup.html

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

## SSH Prerequisites

You usually connect to that machine you just prepared with:

```
ssh -i ~/.ssh/raspberry_local anesowa@<Raspberry Pi IP Address>
```

The `<Raspberry Pi IP Address>` can be replaced with `<Raspberry Pi Host Name>.local` if
on the same LAN network because of the **mDNS**
[Multicast DNS](https://en.wikipedia.org/wiki/Multicast_DNS) solution Raspberry Pi
implements with Avahi (macOS uses Bonjour for mDNS).

If the key file is protected with a passphrase, for Ansible to run smoothly is better if
we make the system we deploy from cache that passphrase, there's two ways:

1. Running `ssh-add ~/.ssh/raspberry_local`

2. Adding an entry to the raspberry host on `~/.ssh/config` as follows:

```
Host 192.168.1.76 rpi-master.local rpi-master.home
  UseKeychain yes
```

If you want to go one step further and avoid to have to pass `-i ~/.ssh/raspberry_local`
to the `ssh` command:

```
Host 192.168.1.76 rpi-master.local rpi-master.home
  IdentityFile ~/.ssh/raspberry_local
  UseKeychain yes
```

## Running Ansible Playbook

First add the hosts on the inventary `ansible/inventory/hosts`:

```
[master]
rpi-master.home

[slaves]
rpi-slave-1.home
rpi-slave-2.home
rpi-slave-3.home
```

Deploy master:

```
eulersson@macbook:~/Devel/anesowa $ ansible-playbook ansible/site.yml -i ansible/hosts --limit master
```

Deploy slaves:

```
eulersson@macbook:~/Devel/anesowa $ ansible-playbook ansible/site.yml -i ansible/hosts --limit slaves
```

[Debugging tasks](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_debugger.html):
If you want to debug the output of a task you can place a debugger as follows:

```
- name: Synchronize project files
  debugger: always
  synchronize:
    src: "{{ project_root }}/"
    dest: /app/anesowa
    rsync_opts:
      - "--exclude-from={{ project_root }}/rsync_exclude.txt"
  tags:
    - sync-project
```

Then after running this task a breakpoint gets hit and you can inspect the command
and its output:

```
eulersson@macbook:~/Devel/anesowa $ ansible-playbook ansible/site.yml -i ansible/hosts --limit master --tags sync-project

PLAY [master] *******************************************************************************************************************************************************************

TASK [Gathering Facts] **********************************************************************************************************************************************************
ok: [rpi-master.home]

TASK [common : Synchronize project files] ***************************************************************************************************************************************
changed: [rpi-master.home]
[rpi-master.home] TASK: common : Synchronize project files (debug)> p result._result
{
 ...

 'cmd': '/usr/local/bin/rsync --delay-updates -F --compress --archive '
        "--rsh='/usr/bin/ssh -S none -i /Users/ramon/.ssh/raspberry_local -o "
        "StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' "
        '--exclude-from=/Users/ramon/Devel/anesowa/rsync_exclude.txt '
        "--out-format='<<CHANGED>>%i %n%L' /Users/ramon/Devel/anesowa/ "
        'anesowa@rpi-master.home:/app/anesowa',
 'failed': False,
 ...
 'msg': '.d..tp...... ./\n'
        ...
        'cd++++++++++ playback-distributor/\n'
        '<f++++++++++ playback-distributor/README.md\n'
        '<f++++++++++ playback-distributor/playback_distri
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
