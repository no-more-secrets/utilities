#!/bin/bash
set -e
set -o pipefail

source ~/dev/utilities/bashlib/util.sh

id="$1"

if [[ -z "$id" ]]; then
  echo -n "Run \`xinput list\` and input the id of the touchpad (or rerun script with id as argument): "
  read id
  (( id > 0 )) || die "invalid id."
fi

prop_name='libinput Natural Scrolling Enabled'

{ xinput list-props $id | grep "$prop_name" >/dev/null; } || \
  die "could not find property '$prop_name' on device $id. " \
      "Run \`xinput list-props $id\` to find the property name to toggle natural scrolling."

current=$(xinput list-props $id | sed -rn 's/\s+libinput Natural Scrolling Enabled \([0-9]+\):\s+([01])$/\1/p')

[[ "$current" == "0" || "$current" == "1" ]] || \
  die "invalid current value for natrual-scrolling-enabled property: $current"

current=$(( 1-current ))

if (( current )); then
  echo "enabling touchpad natural scrolling."
else
  echo "disabling touchpad natural scrolling."
fi

# Set to zero to disable.
xinput --set-prop $id "$prop_name" $current