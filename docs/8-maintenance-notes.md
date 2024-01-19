# Maintenance Notes

TBD.

## Upgrading Versions

TBD.

- TODO: Explain how to maintain poetry versions.

## Replace PulseAudio

It seems the community generally assumes it's getting deprecated in favour of either
high level PipeWire APIs or lower level ALSA.

With PulseAudio there are two features that will be painful to migrate:

- Combinint sinks (speakers).
- Using Bluetooth devices.
