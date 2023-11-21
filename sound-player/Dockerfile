FROM alpine:3.18.4

WORKDIR /anesofi/sound-player/

RUN apk --update add build-base cmake pulseaudio-dev zeromq-dev

COPY . .
