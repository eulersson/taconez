# anesofi: (A)nnoying (Ne)ighbour (So)und (Fi)ghter

IoT Raspberry Pi powered solution to detect, analyse and react against discomforting
sounds.

## Motivation

My neighbour upstairs decided to walk on high heels. I expressed my discomfort and she
took it as a personal attack, rejecting all kind of mediation. Since I received insults
I decided to use the mirror strategy to see if she realizes how unpleasant it becomes.

## Description

This project is composed of various pieces:

1. **AI Sound Detector**: To discriminate and pick-up specific sounds.
2. **Playback Distributor**: To bounce back those sounds with the ability to prefix a
   custom message such as "Stop wearing high-heels! <sound playback>".
3. **Journal** To visualize in graphs the occurrences. Useful for supporting your legal
   claims with objective evidence!

## Technology

This is intended to be run in a group of Raspberry Pi

| Tool | Purpose | Why (Reason) |
|------|---------|-----|
| TensorFlow (Python) | Audio detection | It provides even a higher level API (Keras) that simplifies ML workflows. |
| Next.js (JavaScript) | Data visualization webapp. | It is a full-stack solution that allows to split a React application between server and client components, allowing you to dispatch the database queries from the server and return a rendered React component with all the data displayed, removing any interaction between the browser and the database. We can also have simple REST-style API endpoints that can be listening to the sound detector and writing to database as well as small endpoints for small controls exposed in the frontend. |
| InfluxDB | Record storage. | A time-series database seems very appropiate considering the nature of the data (timestamped). Chosen in favour of Prometheus because it supports `string` data types and it's PUSH-based instead of PULL-based. We don't want to lose occurrences! |
| NFS | Sharing a volume with the audio data. | The database should not get bloated with binary data. Once the audio file is producted, we hash it and store it in the NFS-shared file system |
| 0mq | Communication between the audio detector and the playback receivers. | Instead of having to implement an API, since it's only one instruction, it's simpler to use a PUB-SUB pipeline in the fashionn of a queue. The detector places an element and all playback receivers react playing back the sound. I didn't want another centralized service in the master raspberry pi, so a brokerless solution is more appealing.

## Architecture

(TODO: Attach here the diagram)
