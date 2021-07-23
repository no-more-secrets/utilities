#!/bin/bash
# This script will allow setting the screen backlight to a value
# that is a fraction of the current brightness. This allows set-
# ting it below the default minimum brightness. It will present
# an interactive menu with a few brightness levels. For example,
# selecting "25%" will lower the brightness to 25% of its current
# level.
#
# Recommended usage: first use the usual controls on the keyboard
# to lower the brightness down to the minimum level, then run
# this script to lower it further (will require admin password).
set -e
set -o pipefail

die() {
  echo -e "error: $*"
  exit 1
}

backlight="/sys/class/backlight/intel_backlight"
[[ ! -e "$backlight" ]] && \
    backlight="/sys/class/backlight/gmux_backlight"
[[ ! -e "$backlight" ]] && \
    backlight="/sys/class/backlight/nvidia_0"
[[ ! -e "$backlight" ]] && \
    die "cannot find suitable backlight folder."

cd "$backlight" || die "failed to change to $backlight folder."

[[ -f brightness     ]] || die "failed to find 'brightness' file."
[[ -f max_brightness ]] || die "failed to find 'max_brightness' file."

max_brightness=$(cat max_brightness)

while true; do
  echo "Current brightness: $(cat brightness)/$max_brightness."

  brightness="$(cat brightness)"

  (( brightness >= 10 )) || die "current brightness ($brightness) is not adjustable."

  echo
  echo "Select new brightness level relative to current (the smaller, the darker):"

  select level in "150%" "125%" "75%" "66%" "50%" "33%" "25%"; do
    case "$level" in
     "150%") new_brightness=$(( brightness*3/2 )); break ;;
     "125%") new_brightness=$(( brightness*5/4 )); break ;;
      "75%") new_brightness=$(( brightness*3/4 )); break ;;
      "66%") new_brightness=$(( brightness*2/3 )); break ;;
      "50%") new_brightness=$(( brightness/2   )); break ;;
      "33%") new_brightness=$(( brightness/3   )); break ;;
      "25%") new_brightness=$(( brightness/4   )); break ;;
          *) die "invalid option selected."              ;;
    esac
  done

  (( new_brightness >= 3 )) || die "new brightness level ($new_brightness) is too low."
  (( new_brightness < max_brightness )) || die "new brightness level ($new_brightness) is too high."

  echo "Setting brightness level to: $new_brightness."
  echo "(you may be asked for admin password)"

  sudo su -c "echo $new_brightness > brightness"
done