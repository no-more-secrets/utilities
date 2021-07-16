#!/bin/bash
# This is a repl that allows adjusting the volume of the active
# pulseaudio sink. It is better to just use pulsemixer if it is
# available. But if it isn't, this might do the trick.
set -o pipefail

# ---------------------------------------------------------------
# Parameters
# ---------------------------------------------------------------
refresh_time_secs=2

# ---------------------------------------------------------------
# Helper functions.
# ---------------------------------------------------------------
source ~/dev/utilities/bashlib/util.sh

clear

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

count_active_sinks() {
  sink_table | grep RUNNING | wc -l
}

has_active_sinks() {
  [[ "$(count_active_sinks)" > 0 ]]
}

# This is not supposed to be called unless there is at least one
# active sink.
select_sink() {
  local num_active="$(count_active_sinks)"
  (( num_active > 1 )) && {
    clear
    echo 'Select from available pulseaudio sinks:'
  }
  # Here we are getting the name/description pairs, then trans-
  # posing them into a table so that the user can select.
  sink=$(sink_table       \
    | grep RUNNING        \
    | fzf --select-1      \
    | awk '{ print $2 }')

  (( num_active > 1 )) && clear
  [[ -z "$sink" ]] && \
    die "sink name is empty."
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
  if ! has_active_sinks; then
    echo -en "\r(no audio playing)$(clear_to_eol)"
    # Use this as a sleep that the user can break via enter.
    read -t $refresh_time_secs
    continue
  fi
  select_sink
  while true; do
    volume=$(print_sink_volume)
    echo -en "\rvolume (L/R): $volume up/down [u/d]: $(clear_to_eol)"
    read -t $refresh_time_secs -r c
    if [[ $? == 142 ]]; then
      # the read command hit the timeout.
      break
    fi
    if [[ "$c" == "u" ]]; then
      set_sink_volume "+5%" || break
    elif [[ "$c" == "d" ]]; then
      set_sink_volume "-5%" || break
    fi
    move_up_one_line
  done
done