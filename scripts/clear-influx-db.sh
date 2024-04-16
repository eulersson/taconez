#!/bin/sh

curl -v -X POST \
  'http://localhost:8086/api/v2/delete?org=taconez&bucket=taconez' \
  -H 'Authorization: Token no_token' \
  -d '{
        "start": "1970-01-01T00:00:00Z",
        "stop": "2099-01-01T00:00:00Z",
        "predicate": "_measurement=\"detections\""
      }'