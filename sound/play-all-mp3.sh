#!/bin/bash
set -e
set -o pipefail

for song in *.mp3; do
  ffplay -nodisp -autoexit "$song"
done
