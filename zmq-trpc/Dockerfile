FROM node:20.11.0-bookworm as base

WORKDIR /app/zmq-trpc/

RUN apt-get update && apt-get install -y git

COPY package.json package-lock.json .

RUN npm install

COPY . .

FROM base as server

EXPOSE 9976

CMD npm run dev:server

FROM base as client

CMD npm run dev:client
