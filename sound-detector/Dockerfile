FROM python:3.10.13-slim-bookworm

WORKDIR /anesowa/sound-detector/

# Slim won't have `gcc` which is needed by building some Python depenencies.
#
#   https://github.com/docker-library/python/issues/60#issuecomment-134322383
#
# The --no-install-recommends helps limit some of the install so that you can be more
# explicit about what gets installed.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    gcc libc-dev portaudio19-dev pulseaudio-utils

# TODO: Cleanup gcc and libc-dev and other build-time dependencies after installing poetry depenencies?

COPY pyproject.toml poetry.lock ./

RUN pip install --upgrade pip setuptools wheel \
 && pip install --upgrade keyrings.alt \
 && pip install poetry==1.7.1 \
 && poetry config virtualenvs.create false

RUN poetry install --no-interaction

COPY . ./
