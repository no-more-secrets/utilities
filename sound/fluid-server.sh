#!/bin/bash

pgrep fluidsynth &>/dev/null && {
  echo 'already running.'
  exit 1
}

fluidsynth --server --audio-driver=alsa /usr/share/sounds/sf2/FluidR3_GM.sf2
