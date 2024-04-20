"""
Database operations.
"""

import influxdb_client

from influxdb_client.client.write_api import SYNCHRONOUS

from sound_detector.config import config


def write_db_entry(detected_class_slug: str, score: float, relative_sound_path: str):
    """Writes the sound occurrence to the Influx DB store.

    Args:
        detected_class_slug (str): The slug of the detected sound class.
        score (float): The prediction for that class, the higher the more confident.
        relative_sound_path (str): The relative path to the sound file.
    """
    client = influxdb_client.InfluxDBClient(
        url=config.influx_db_addr, org="taconez", token=config.influx_db_token
    )

    write_api = client.write_api(write_options=SYNCHRONOUS)
    p = (
        influxdb_client.Point("detections")
        .tag("sound", detected_class_slug)
        .field("score", score)
        .field("audio_file_path", relative_sound_path)
    )
    write_api.write(bucket="taconez", org="taconez", record=p)