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

if (( is_linux )); then
    driver=alsa
    if which jack_lsp &>/dev/null; then
        jack_lsp &>/dev/null && {
          echo '*** JACK running: using --audio-driver=jack'
          driver=jack
        }
    fi
else
    # OSX
    driver=coreaudio
fi

echo "Using driver: $driver"

fluidsynth --server --audio-driver=$driver $sf
