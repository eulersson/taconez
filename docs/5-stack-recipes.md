# Stack Recipes

This document is intended to show simple examples of each tool that is to be integrated
into this project.

## Database (InfluxDB)

This project uses **InfluxDB**, a times series database is to be used to log disturbing
sound occurrences.

These guides are used as reference:

- [Install InfluxDB on Raspberry Pi](https://docs.influxdata.com/influxdb/v2/install/?t=Raspberry+Pi)
- [InfluxDB Docs | Get started writing data](https://docs.influxdata.com/influxdb/v2/get-started/write)
- [InfluxDB Docs | Get started querying data](https://docs.influxdata.com/influxdb/v2/get-started/query)

**NOTE**: This document is for reference, and you don't need to provision new Raspberry
Pis with those commands since it's done with an Ansible playbook. This is for me to
remember the steps before writing the Ansible Playbook. Read
[Provisioning & Deployment](/docs/1-provisioning-and-deployment.md).

### Installation

Installing InfluxDB server:

```
anesowa@raspberrypi:~ $ uudo apt update
anesowa@raspberrypi:~ $ sudo apt upgrade
anesowa@raspberrypi:~ $ curl https://repos.influxdata.com/influxdata-archive.key | gpg --dearmor | sudo tee /usr/share/keyrings/influxdb-archive-keyring.gpg >/dev/null
anesowa@raspberrypi:~ $ echo "deb [signed-by=/usr/share/keyrings/influxdb-archive-keyring.gpg] https://repos.influxdata.com/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
anesowa@raspberrypi:~ $ sudo apt install influxdb2
anesowa@raspberrypi:~ $ sudo systemctl unmask influxdb
anesowa@raspberrypi:~ $ sudo systemctl enable influxdb
anesowa@raspberrypi:~ $ sudo systemctl start influxdb
```

```
curl -O https://dl.influxdata.com/influxdb/releases/influxdb2_2.7.4-1_arm64.deb
sudo dpkg -i influxdb2_2.7.4-1_arm64.deb
sudo service influxdb start
```

```
# amd64
wget https://dl.influxdata.com/influxdb/releases/influxdb2-client-2.7.3-linux-amd64.tar.gz
```

### Configuration

```
# Setup instance with initial user, org, bucket.
anesowa@raspberrypi:~ $ influx setup \
  --username anesowa \
  --password ">R7#$gjf>2@dLXUU<" \
  --token XwSAJxRKHFkFL9wLiA4pPrDeXed
  --org anesowa \
  --bucket anesowa \
  --force

# Create an All Access API Token to use when creating resources on the database.
anesowa@raspberrypi:~ $ influx auth create \
  --all-access \
  --host http://localhost:8086 \
  --org anesowa \
  --token XwSAJxRKHFkFL9wLiA4pPrDeXed
ID                      Description     Token                                                                                           User Name       User ID                 Permissions
0c0d6b05a3a6d000                        MkNsrWGwIpZEZvyRGK49-ftUgqoQCmY4rmisobotxxPr_M_Cx_IBxjge_KgOQUswdQr2tmFjzDLmRetkfg0qcg==        supermaster          0c0d68543ca6d000        [read:orgs/8e706e7c04613c15/authorizations write:orgs/8e706e7c04613c15/authorizations read:orgs/8e706e7c04613c15/buckets write:orgs/8e706e7c04613c15/buckets read:orgs/8e706e7c04613c15/dashboards write:orgs/8e706e7c04613c15/dashboards read:/orgs/8e706e7c04613c15 read:orgs/8e706e7c04613c15/sources write:orgs/8e706e7c04613c15/sources read:orgs/8e706e7c04613c15/tasks write:orgs/8e706e7c04613c15/tasks read:orgs/8e706e7c04613c15/telegrafs write:orgs/8e706e7c04613c15/telegrafs read:/users/0c0d68543ca6d000 write:/users/0c0d68543ca6d000 read:orgs/8e706e7c04613c15/variables write:orgs/8e706e7c04613c15/variables read:orgs/8e706e7c04613c15/scrapers write:orgs/8e706e7c04613c15/scrapers read:orgs/8e706e7c04613c15/secrets write:orgs/8e706e7c04613c15/secrets read:orgs/8e706e7c04613c15/labels write:orgs/8e706e7c04613c15/labels read:orgs/8e706e7c04613c15/views write:orgs/8e706e7c04613c15/views read:orgs/8e706e7c04613c15/documents write:orgs/8e706e7c04613c15/documents read:orgs/8e706e7c04613c15/notificationRules write:orgs/8e706e7c04613c15/notificationRules read:orgs/8e706e7c04613c15/notificationEndpoints write:orgs/8e706e7c04613c15/notificationEndpoints read:orgs/8e706e7c04613c15/checks write:orgs/8e706e7c04613c15/checks read:orgs/8e706e7c04613c15/dbrp write:orgs/8e706e7c04613c15/dbrp read:orgs/8e706e7c04613c15/notebooks write:orgs/8e706e7c04613c15/notebooks read:orgs/8e706e7c04613c15/annotations write:orgs/8e706e7c04613c15/annotations read:orgs/8e706e7c04613c15/remotes write:orgs/8e706e7c04613c15/remotes read:orgs/8e706e7c04613c15/replications write:orgs/8e706e7c04613c15/replications]

# Configure connection configuration preset to use.
anesowa@raspberrypi:~ $ influx config create \
  --config-name anesowa \
  --host-url http://localhost:8086 \
  --org anesowa \
  --token MkNsrWGwIpZEZvyRGK49-ftUgqoQCmY4rmisobotxxPr_M_Cx_IBxjge_KgOQUswdQr2tmFjzDLmRetkfg0qcg==
Active  Name            URL                     Org
        anesowa         http://localhost:8086   anesowa

# Generate timestamps with:
anesowa@raspberrypi:~ $ date +%s
1698755458

# Create an entry:
anesowa@raspberrypi:~ $ influx write --bucket anesowa --precision s "
acons,sound=high_heel soundfile=\"/path/to/soundfile.wav\" $(date +%s)
"

# Querying:
anesowa@raspberrypi:~ $ influx query 'from(bucket: "anesowa") |> range(start: 2020-10-10T08:00:00Z, stop: 2024-10-10T08:00:00Z) |> filter(fn: (r) => r.\_measurement == "annoying_sounds")'
Result: \_result
Table: keys: [_start, _stop, _field, _measurement, room]
\_start:time \_stop:time \_field:string \_measurement:string room:string \_time:time \_value:string

---

2020-10-10T08:00:00.000000000Z 2024-10-10T08:00:00.000000000Z soroll tacons neus 2023-10-31T12:38:54.000000000Z /path/to/file.wav
Table: keys: [_start, _stop, _field, _measurement, room]
\_start:time \_stop:time \_field:string \_measurement:string room:string \_time:time \_value:string

---

2020-10-10T08:00:00.000000000Z 2024-10-10T08:00:00.000000000Z soroll tacons tete 2023-10-31T15:11:45.984090516Z /to/file2.wav
```

Using the Python client (`pip install influxdb-client`) is easy:

```
import influxdb_client
from influxdb_client.client.write_api import SYNCHRONOUS

client = influxdb_client.InfluxDBClient(
url="http://localhost:8086",
org="anesowa",
token="MkNsrWGwIpZEZvyRGK49-ftUgqoQCmY4rmisobotxxPr_M_Cx_IBxjge_KgOQUswdQr2tmFjzDLmRetkfg0qcg==",
)

write_api = client.write_api(write_options=SYNCHRONOUS)
p = influxdb_client.Point("annoying_sounds").tag("sound", "high_heel").field("soundfile", "/to/file2.wav")
write_api.write(bucket="anesowa", org="anesowa", record=p)

```

## File Sharing (NFS)

This project uses **NFS** for synchronizing the audio detections so they can be replayed
in all the Raspberry Pis.

The master Raspberry Pi should set up an NFS share mounted on `/mnt/nfs/anesowa` so that
all slaves can connect to it.

Considerations:

- Only allow connecting within the local network.
- Only allow the operating user of the stack (in my case `anesowa`) to connect to it.
  When trying to connect from another environment the UNIX user and password will then
  be required instead of allowing anonymous connections.

Hardening should be studied on a second iteration.

These guides is taken as reference:

- [How to Setup Raspberry Pi NFS Server](https://pimylifeup.com/raspberry-pi-nfs/)
- [Connecting to an NFS Share on the Raspberry Pi](https://pimylifeup.com/raspberry-pi-nfs-client/)
- [The /etc/exports Configuration File](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/5/html/deployment_guide/s1-nfs-server-config-exports)

**NOTE**: This guide assumes the master Raspberry Pi runs at `192.168.1.76` in the
network.

**NOTE**: This document is a reference, and you don't need to provision new Raspberry
Pis with those commands since it's done with an Ansible playbook. This is for me to
remember the steps before writing the Ansible Playbook. Read
[Provisioning](/docs/provisioning.md) for more.

### Server Setup

Run this on the Raspberry Pi:

```
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install nfs-kernel-server -y
sudo mkdir -p /mnt/nfs/anesowa
sudo chown -R anesowa:anesowa /mnt/nfs/anesowa
sudo find /mnt/nfs/anesowa/ -type d -exec chmod 755 {} \;
sudo find /mnt/nfs/anesowa/ -type f -exec chmod 644 {} \;

```

Get the user that will be used on anonymous users.

```
# TODO: Do not allow anonymous access.
id anesowa
# Output: <anesowa-id>
```

Open file `/etc/exports` and set this line, replacing `192.168.1/24` with your local
network CIDR. This determines from where connections will be accepted:

```
/mnt/nfs/anesowa 192.168.1.0/24(rw,all_squash,insecure,no_subtree_check,anonuid=1000,anongid=1000)
```

- `insecure` is needed otherwise from macOS I cannot connect from macOS.

Export the changes:

```
sudo exportfs -ra
```

### Connecting from a macOS

To connect using _File Explorer > Go > Connect to Server_ (<kbd>⌘</kbd> + <kbd>K</kbd>)
and type in `nfs://raspberrypi.local/mnt/nfs/anesowa`.

### Connecting from Other Raspberry Pi

If nfs-common is not installed, install it (it usually is installed by default).

```
sudo apt update
sudo apt full-upgrade
sudo apt install nfs-common
```

Then create a folder and mount the network volume to that folder, for instance a slave
Raspberry Pi would connect to the master as follows:

```
sudo mkdir -p /mnt/nfs/anesowa
sudo chmod 755 /mnt/nfs/anesowa
sudo mount -t nfs raspberrypi.local:/mnt/nfs/anesowa /mnt/nfs/anesowa
```
