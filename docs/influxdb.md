# InfluxDB

A times series database is to be used to log noise occurrences.

These guides are used as reference:

- [Installing InfluxDB to the Raspberry Pi](https://pimylifeup.com/raspberry-pi-influxdb/)
- [InfluxDB Docs | Get started writing data](https://docs.influxdata.com/influxdb/v2/get-started/write)
- [InfluxDB Docs | Get started querying data](https://docs.influxdata.com/influxdb/v2/get-started/query)


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

# CLI

TODO.

# Python CLI

TODO.