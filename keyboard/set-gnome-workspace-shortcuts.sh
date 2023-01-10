#!/bin/bash
# This will set gnome keybindings to allow switching workspaces
# with Super-N.
set -eo pipefail

set_binding() {
  local n=$1
  echo gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "[\"<Super>$1\"]"
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "[\"<Super>$1\"]"
}

for (( i=1; i<=9; i++ )); do
  set_binding $i
done