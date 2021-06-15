#!/bin/bash
set -e
set -o pipefail

sudo true

clear

python ~/dev/utilities/color/24-bit-color.py
echo 'enter to select and exit; escape for default.'

prev_color=

while true; do
  color=$(~/dev/utilities/color/pick-color-from-screen.sh)
  color="${color//#/}"
  # We need a way for the user to break from this loop. This is
  # very important, since otherwise it is very difficult to es-
  # cape because the pick-color.sh program takes over input, and
  # so e.g. Ctrl-C won't work.
  [[ "$color" == "$prev_color" ]] && break
  prev_color="$color"
  echo -en "color: $color\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
  sudo ~/dev/utilities/color/set-keyboard-backlight-color.py $color
done

clear
echo "selected: #$color"