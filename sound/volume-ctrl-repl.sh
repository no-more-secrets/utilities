#!/bin/bash
# This is a repl that allows adjusting the volume of a given
# pulseaudio sink.
set -e
set -o pipefail

# ---------------------------------------------------------------
# Helper functions.
# ---------------------------------------------------------------
source ~/dev/utilities/bashlib/util.sh

# Not really necessary, but nice.
bye() {
  echo
  echo bye.
  exit 0
}
trap bye INT

# ---------------------------------------------------------------
# Get a pulseaudio sink.
# ---------------------------------------------------------------
echo 'Select from available pulseaudio sinks:'
# Here we are getting the name/description pairs, then trans-
# posing them into a table so that the user can select.
sink=$(pactl list sinks                \
  | grep -E 'Name:|Description:'       \
  | sed -r 's/\s+[a-zA-Z]+: //g'       \
  | tr ' ' '_'                         \
  | xargs -n2 echo                     \
  | column --table -N Name,Description \
  | fzf --select-1                     \
  | awk '{ print $1 }')

echo "selected sink: $sink."
[[ ! -z "$sink" ]] || \
  die "failed to get sink name."

# ---------------------------------------------------------------
# Inc / Dec Volume.
# ---------------------------------------------------------------
set_sink_volume() {
  pactl set-sink-volume "$sink" $1
}

print_sink_volume() {
  local vol
  vol=$(pactl list sinks      \
    | grep -E 'Name:|Volume:' \
    | grep -v 'Base Volume'   \
    | transpose 2             \
    | grep "$sink"            \
    | awk '{ print $7 "/" $14 }')
  echo -en "${c_yellow}${c_bold}$vol${c_norm}"
}

# Test that we can set it at all.
set_sink_volume "+0%"

# ---------------------------------------------------------------
# The REPL
# ---------------------------------------------------------------
while true; do
  clear
  echo -n 'volume (L/R): '
  print_sink_volume
  echo -n ' up/down [u/d]: '
  read c
  if [[ "$c" == "u" ]]; then
    set_sink_volume "+5%"
  elif [[ "$c" == "d" ]]; then
    set_sink_volume "-5%"
  fi
done