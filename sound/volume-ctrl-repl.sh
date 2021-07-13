#!/bin/bash
# This is a repl that allows adjusting the volume of the active
# pulseaudio sink.
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
sink=

# This will generate a table with three columns: State, Name, and
# Description of the pulseaudio sink.
sink_table() {
  pactl list sinks                        \
    | grep -E 'State:|Name:|Description:' \
    | sed -r 's/\s+[a-zA-Z]+: //g'        \
    | tr ' ' '_'                          \
    | xargs -n3 echo                      \
    | column -t
}

has_active_sinks() {
  [[ "$(sink_table | grep RUNNING | wc -l)" > 0 ]] 
}

# This is not supposed to be called unless there is at least one
# active sink.
select_sink() {
  echo 'Select from available pulseaudio sinks:'
  # Here we are getting the name/description pairs, then trans-
  # posing them into a table so that the user can select.
  sink=$(sink_table       \
    | grep RUNNING        \
    | fzf --select-1      \
    | awk '{ print $2 }')

  echo "selected sink: $sink."
  [[ ! -z "$sink" ]] && break
  warn "sink name is empty."
}

# ---------------------------------------------------------------
# Inc / Dec Volume.
# ---------------------------------------------------------------
set_sink_volume() {
  pactl set-sink-volume "$sink" "$1" || {
    warn "failed to set sink volume."
    return 1
  }
  return 0
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

# ---------------------------------------------------------------
# The REPL
# ---------------------------------------------------------------
# This will wait for the user to hit u/d to inc/dec the volume
# for the active sink. However, every 5 seconds of inactivity it
# will re-check the list of active sinks to see if they have
# changed. An example of this is if the sound is coming out of
# builtin speakers and then a bluetooth speaker is connected.
while true; do
  clear
  if ! has_active_sinks; then
    echo '(no active pulseaudio sinks found; there is no audio playing)'
    # Use this as a sleep that the user can break via enter.
    read -t 10
    continue
  fi
  select_sink
  while true; do
    clear
    echo -n 'volume (L/R): '
    print_sink_volume
    echo -n ' up/down [u/d]: '
    read -t 5 -r c
    if [[ $? == 142 ]]; then
      break
    fi
    if [[ "$c" == "u" ]]; then
      set_sink_volume "+5%" || break
    elif [[ "$c" == "d" ]]; then
      set_sink_volume "-5%" || break
    fi
  done
done