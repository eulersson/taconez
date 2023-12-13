FROM alpine:3.18.4

WORKDIR /anesofi/playback-distributor/

RUN apk --update add build-base cmake zeromq-dev

COPY . .

RUN cmake -S . -B build --fresh && cmake --build build --verbose

# TODO: Cleanup build-time dependencies.
