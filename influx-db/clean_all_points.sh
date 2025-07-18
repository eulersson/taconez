#!/bin/bash

# Helpful utility script to clean all points from database while developing.

influx delete --org your_org --bucket your_bucket --start '1970-01-01T00:00:00Z' --stop $(date -u +"%Y-%m-%dT%H:%M:%SZ")