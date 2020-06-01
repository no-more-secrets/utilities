#!/bin/bash
set -e
set -o pipefail

which system76-power &>/dev/null || exit 0

curr_mode=$(system76-power profile | sed -rn 's/Power Profile: (.*)/\1/p')
curr_mode="${curr_mode,,}"

usage_exit() {
  echo 1>&2 "usage: $(basename $(realpath $0)) [get|set <target>]"
  echo 1>&2 "       Run with no arguments to interactive set mode."
  exit 1
}

if (( $# == 2 )); then
  if [[ "$1" == set ]]; then
    system76-power profile $sel_mode $2
    exit 0
  fi
elif (( $# == 1 )); then
  if [[ "$1" == get ]]; then
    echo "$curr_mode"
    exit 0
  fi
elif (( $# == 0 )); then
  echo "current: $curr_mode"
  avail_modes=( performance balanced battery )
  avail_modes=( "${avail_modes[@]/$curr_mode}" )
  select_mode() {
    {
      echo cancel
      for mode in ${avail_modes[@]}; do
        echo "$mode"
      done
    } | fzf
  }
  sel_mode=$(select_mode)
  [[ "$sel_mode" == ''       ]] && exit 0
  [[ "$sel_mode" == 'cancel' ]] && exit 0
  system76-power profile $sel_mode
  exit 0
fi

usage_exit