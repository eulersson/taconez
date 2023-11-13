# InfluxDB

A times series database is to be used to log noise occurrences.

These guides are used as reference:

- [Install InfluxDB on Raspberry Pi](https://docs.influxdata.com/influxdb/v2/install/?t=Raspberry+Pi)
- [InfluxDB Docs | Get started writing data](https://docs.influxdata.com/influxdb/v2/get-started/write)
- [InfluxDB Docs | Get started querying data](https://docs.influxdata.com/influxdb/v2/get-started/query)

**NOTE**: This document is a reference, and you don't need to provision new Raspberry Pis
with those commands since it's done with an Ansible playbook. This is for me to remember
the steps before writing the Ansible Playbook. Read
[Provisioning](/docs/provisioning.md) for more.

# Instalation

```
sudo apt update
sudo apt upgrade
curl https://repos.influxdata.com/influxdata-archive.key | gpg --dearmor | sudo tee /usr/share/keyrings/influxdb-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/influxdb-archive-keyring.gpg] https://repos.influxdata.com/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
sudo apt install influxdb2
sudo systemctl unmask influxdb
sudo systemctl enable influxdb
sudo systemctl start influxdb
```

```
# influxdata-archive_compat.key GPG fingerprint:
#     9D53 9D90 D332 8DC7 D6C8 D3B9 D8FF 8E1F 7DF8 B07E
wget -q https://repos.influxdata.com/influxdata-archive_compat.key
echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list

sudo apt update && sudo apt install influxdb2
```

# Configuration

```
$ influx setup \
  --username elohim \
  --password ">R7#$gjf>2@dLXUU<" \
  --token XwSAJxRKHFkFL9wLiA4pPrDeXed
  --org anesofi \
  --bucket anesofi \
  --force

$ influx auth create \
  --all-access \
  --host http://localhost:8086 \
  --org anesofi \
  --token XwSAJxRKHFkFL9wLiA4pPrDeXed
  ID                      Description     Token                                                                                           User Name       User ID                 Permissions
0c0d6b05a3a6d000                        MkNsrWGwIpZEZvyRGK49-ftUgqoQCmY4rmisobotxxPr_M_Cx_IBxjge_KgOQUswdQr2tmFjzDLmRetkfg0qcg==        elohim          0c0d68543ca6d000        [read:orgs/8e706e7c04613c15/authorizations write:orgs/8e706e7c04613c15/authorizations read:orgs/8e706e7c04613c15/buckets write:orgs/8e706e7c04613c15/buckets read:orgs/8e706e7c04613c15/dashboards write:orgs/8e706e7c04613c15/dashboards read:/orgs/8e706e7c04613c15 read:orgs/8e706e7c04613c15/sources write:orgs/8e706e7c04613c15/sources read:orgs/8e706e7c04613c15/tasks write:orgs/8e706e7c04613c15/tasks read:orgs/8e706e7c04613c15/telegrafs write:orgs/8e706e7c04613c15/telegrafs read:/users/0c0d68543ca6d000 write:/users/0c0d68543ca6d000 read:orgs/8e706e7c04613c15/variables write:orgs/8e706e7c04613c15/variables read:orgs/8e706e7c04613c15/scrapers write:orgs/8e706e7c04613c15/scrapers read:orgs/8e706e7c04613c15/secrets write:orgs/8e706e7c04613c15/secrets read:orgs/8e706e7c04613c15/labels write:orgs/8e706e7c04613c15/labels read:orgs/8e706e7c04613c15/views write:orgs/8e706e7c04613c15/views read:orgs/8e706e7c04613c15/documents write:orgs/8e706e7c04613c15/documents read:orgs/8e706e7c04613c15/notificationRules write:orgs/8e706e7c04613c15/notificationRules read:orgs/8e706e7c04613c15/notificationEndpoints write:orgs/8e706e7c04613c15/notificationEndpoints read:orgs/8e706e7c04613c15/checks write:orgs/8e706e7c04613c15/checks read:orgs/8e706e7c04613c15/dbrp write:orgs/8e706e7c04613c15/dbrp read:orgs/8e706e7c04613c15/notebooks write:orgs/8e706e7c04613c15/notebooks read:orgs/8e706e7c04613c15/annotations write:orgs/8e706e7c04613c15/annotations read:orgs/8e706e7c04613c15/remotes write:orgs/8e706e7c04613c15/remotes read:orgs/8e706e7c04613c15/replications write:orgs/8e706e7c04613c15/replications]

$ influx config create \
  --config-name get-started \
  --host-url http://localhost:8086 \
  --org anesofi \
  --token MkNsrWGwIpZEZvyRGK49-ftUgqoQCmY4rmisobotxxPr_M_Cx_IBxjge_KgOQUswdQr2tmFjzDLmRetkfg0qcg==
Active  Name            URL                     Org
        get-started     http://localhost:8086   anesofi

$ influx bucket create --name get-started
ID                      Name            Retention       Shard group duration    Organization ID         Schema Type
a1bc7a05ece4216a        get-started     infinite        168h0m0s                8e706e7c04613c15        implicit

influx write \
  --bucket get-started \
  --precision s "
home,room=Living\ Room temp=21.1,hum=35.9,co=0i 1641024000
home,room=Kitchen temp=21.0,hum=35.9,co=0i 1641024000
home,room=Living\ Room temp=21.4,hum=35.9,co=0i 1641027600
home,room=Kitchen temp=23.0,hum=36.2,co=0i 1641027600
home,room=Living\ Room temp=21.8,hum=36.0,co=0i 1641031200
home,room=Kitchen temp=22.7,hum=36.1,co=0i 1641031200
home,room=Living\ Room temp=22.2,hum=36.0,co=0i 1641034800
home,room=Kitchen temp=22.4,hum=36.0,co=0i 1641034800
home,room=Living\ Room temp=22.2,hum=35.9,co=0i 1641038400
home,room=Kitchen temp=22.5,hum=36.0,co=0i 1641038400
home,room=Living\ Room temp=22.4,hum=36.0,co=0i 1641042000
home,room=Kitchen temp=22.8,hum=36.5,co=1i 1641042000
home,room=Living\ Room temp=22.3,hum=36.1,co=0i 1641045600
home,room=Kitchen temp=22.8,hum=36.3,co=1i 1641045600
home,room=Living\ Room temp=22.3,hum=36.1,co=1i 1641049200
home,room=Kitchen temp=22.7,hum=36.2,co=3i 1641049200
home,room=Living\ Room temp=22.4,hum=36.0,co=4i 1641052800
home,room=Kitchen temp=22.4,hum=36.0,co=7i 1641052800
home,room=Living\ Room temp=22.6,hum=35.9,co=5i 1641056400
home,room=Kitchen temp=22.7,hum=36.0,co=9i 1641056400
home,room=Living\ Room temp=22.8,hum=36.2,co=9i 1641060000
home,room=Kitchen temp=23.3,hum=36.9,co=18i 1641060000
home,room=Living\ Room temp=22.5,hum=36.3,co=14i 1641063600
home,room=Kitchen temp=23.1,hum=36.6,co=22i 1641063600
home,room=Living\ Room temp=22.2,hum=36.4,co=17i 1641067200
home,room=Kitchen temp=22.7,hum=36.5,co=26i 1641067200
"
```

Generate timestamps with:

```
$ date +%s
1698755458

cooper@neptune:~ $ influx write --bucket get-started --precision s "
tacons,room=neus soroll=\"/path/to/file.wav\" $(date +%s)
"
```

Using the Python client is easy:

```
import influxdb_client
from influxdb_client.client.write_api import SYNCHRONOUS

client = influxdb_client.InfluxDBClient(
url="http://localhost:8086",
org="anesofi",
token="MkNsrWGwIpZEZvyRGK49-ftUgqoQCmY4rmisobotxxPr_M_Cx_IBxjge_KgOQUswdQr2tmFjzDLmRetkfg0qcg==",
)

write_api = client.write_api(write_options=SYNCHRONOUS)
p = influxdb_client.Point("tacons").tag("room", "tete").field("soroll", "/to/file2.wav")
write_api.write(bucket="get-started", org="anesofi", record=p)
```

Querying from the CLI:

```
(env) cooper@neptune:~ $ influx query 'from(bucket: "get-started") |> range(start: 2020-10-10T08:00:00Z, stop: 2024-10-10T08:00:00Z) |> filter(fn: (r) => r.\_measurement == "tacons")'
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
