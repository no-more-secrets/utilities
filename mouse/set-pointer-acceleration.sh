#!/bin/bash
set -e
set -o pipefail

source ~/dev/utilities/bashlib/util.sh

id="$1"

if [[ -z "$id" ]]; then
  xinput list
  echo
  echo -n "Input the id of the mouse or touchpad (or rerun script with id as argument): "
  read id
  (( id > 0 )) || die "invalid id."
fi

prop_name='libinput Accel Speed'

{ xinput list-props $id | grep "$prop_name"; } || \
  die "could not find property '$prop_name' on device $id. " \
      "Run \`xinput list-props $id\` to find the property name of the mouse or touchpad acceleration."

echo "Select abs value of pointer acceleration (0=normal):"
value=$(echo " .9 (fastest)
 .7
 .5
 .3
 .1
  0
-.1
-.3
-.5
-.7
-.9 (slowest)" | fzf | awk '{print $1}')

[[ ! -z "$value" ]]

echo "setting pointer acceleration to $value."
xinput --set-prop $id "$prop_name" $value