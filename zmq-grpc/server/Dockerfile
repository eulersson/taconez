FROM golang:1.22.0-alpine as base

EXPOSE 9976

FROM base as builder

RUN apk add --update --no-cache protoc protobuf-dev \
 && go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28 \
 && go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2

WORKDIR /src

COPY server/go.mod server/go.sum ./
RUN go mod download

COPY taconez_grpc.proto .

COPY server/server/main.go ./server/main.go

RUN mkdir -p ./grpc_definition && \
  protoc \
  --go_out=./grpc_definition \
  --go_opt=paths=source_relative \
  --go-grpc_out=./grpc_definition \
  --go-grpc_opt=paths=source_relative \
  taconez_grpc.proto

RUN CGO_ENABLED=0 GOOS=linux go build -o /bin/taconez-rpc-server server/main.go

FROM builder as development

WORKDIR /src

CMD taconez-rpc-server

FROM base as production

COPY --from=builder /bin/taconez-rpc-server /bin

CMD taconez-rpc-server