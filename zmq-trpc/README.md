# tRPC Proof of Concept

```
docker build -t zmq-trpc-server --target server .
docker build -t zmq-trpc-client --target client .
```

```
docker run --rm -it -p 9976:9976 zmq-trpc-server
docker run --rm -it -e TRPC_SERVER_HOST_NAME=host.docker.internal zmq-trpc-client
``