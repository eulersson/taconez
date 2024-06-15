#!/bin/sh

curl -v -X POST \
  'http://localhost:8086/api/v2/delete?org=taconez&bucket=taconez' \
  -H 'Authorization: Token vsC0Q_nELv6zi1rjkRKjqVnqdwWoRemazl-zfyWiO1bpfK9ET3WdEL3rAPZVAD_9HtPC0ij7qP7uXgkbKkIiXA==' \
  -d '{
        "start": "1970-01-01T00:00:00Z",
        "stop": "2099-01-01T00:00:00Z",
        "predicate": "_measurement=\"detections\""
      }'