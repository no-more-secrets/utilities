#!/bin/bash
set -e
set -o pipefail

pgrep fluidsynth &>/dev/null && {
  echo 'already running.'
  exit 1
}

echo 'Select sound font:'

sfs="/usr/share/sounds/sf2/*.sf2"

[[ -d "$HOME/dev/sound/sf2" ]] &&
    sfs="$sfs $HOME/dev/sound/sf2/*.sf2"

sf=$(ls $sfs | fzf --no-select-1) || {
  echo 'failed to search for sound fonts.'
  exit 1
}

[[ -z "$sf" ]] && {
  echo 'no sound font selected.'
  exit 1
}

echo "selected: $sf"

fluidsynth --server --audio-driver=alsa $sf
