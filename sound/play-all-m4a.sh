#!/bin/bash
set -e
set -o pipefail

for song in *.m4a; do
  ffplay -nodisp -autoexit "$song"
done
