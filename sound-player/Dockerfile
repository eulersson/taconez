FROM alpine:3.18.4

WORKDIR /anesowa/sound-player

RUN apk --update add build-base cmake pulseaudio-dev zeromq-dev

# Installs CLI tools like `paplay` useful for debugging.
RUN apk add pulseaudio-utils

COPY ../lib /anesowa/lib
COPY . .

RUN cmake -S . -B build --fresh && cmake --build build --verbose

# TODO: Cleanup build-time dependencies.
