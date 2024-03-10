"""
Database operations.
"""

import influxdb_client

from influxdb_client.client.write_api import SYNCHRONOUS

from sound_detector.config import config


def write_db_entry(detected_sound_name, relative_sound_path):
    """Writes the sound occurrence to the Influx DB store.

    Args:
        class_name: Name of the highest scoring label the sound matches.
        relative_sound_path: Path relative to DETECTED_RECORDINGS_DIR, e.g.
          `2023/12/10/2023-12-10-16-43.wav`.
    """
    client = influxdb_client.InfluxDBClient(
        url=config.influx_db_addr, org="taconez", token=config.influx_db_token
    )

    write_api = client.write_api(write_options=SYNCHRONOUS)
    p = (
        influxdb_client.Point("detections")
        .field("sound", detected_sound_name)
        .field("audio_file_path", relative_sound_path)
    )
    write_api.write(bucket="taconez", org="taconez", record=p)
