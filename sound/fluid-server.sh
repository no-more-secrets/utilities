#!/bin/bash

pgrep fluidsynth &>/dev/null && {
  echo 'already running.'
  exit 1
}

echo 'Select sound font:'

sf_dir=/usr/share/sounds/sf2

sf=$(ls $sf_dir | fzf)

[[ -z "$sf" ]] && {
  echo 'no sound font selected.'
  exit 1
}

fluidsynth --server --audio-driver=alsa $sf_dir/$sf
