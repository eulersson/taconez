#!/bin/sh

cmake -S . -B build --fresh && cmake --build build --verbose
