FROM node:20.11.0-alpine as base

RUN apk add --update --no-cache protoc

WORKDIR /app

COPY client/package.json client/package-lock.json ./

RUN npm install

COPY taconez_grpc.proto .

COPY . .

RUN mkdir -p ./lib/rpc protoc \
 && protoc \
      --plugin=./node_modules/.bin/protoc-gen-ts_proto \
      --ts_proto_out=./lib/rpc \
      --ts_proto_opt=outputServices=grpc-js \
      ./taconez_grpc.proto

FROM base as development

CMD npm run dev