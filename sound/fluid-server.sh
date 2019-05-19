#!/bin/bash
set -e
set -o pipefail

[[ "$(uname)" == Linux ]] && is_linux=1 || is_linux=0

pgrep fluidsynth &>/dev/null && {
  echo 'already running.'
  exit 1
}

echo 'Select sound font:'

(( is_linux )) &&                      \
  sfs="/usr/share/sounds/sf2/*.sf2" || \
  sfs="/opt/local/share/sounds/sf2/*.sf2"

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

(( is_linux )) && driver=alsa || driver=coreaudio

pgrep jackd >/dev/null && {
  echo 'jack detected: using --audio-driver=jack'
  driver=jack
}

fluidsynth --server --audio-driver=$driver $sf
