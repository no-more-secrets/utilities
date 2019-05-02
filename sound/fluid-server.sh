#!/bin/bash

pgrep fluidsynth &>/dev/null && {
  echo 'already running.'
  exit 1
}

echo 'Select sound font:'

sfs="/usr/share/sounds/sf2/*.sf2 $HOME/dev/sound/sf2/*.sf2"

sf=$(ls $sfs | fzf)

[[ -z "$sf" ]] && {
  echo 'no sound font selected.'
  exit 1
}

echo "selected: $sf"

fluidsynth --server --audio-driver=alsa $sf
