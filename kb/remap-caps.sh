#!/bin/bash
set -e

# Try one each of these.

setxkbmap -option caps:ctrl_modifier

# gsettings set org.gnome.desktop.input-sources xkb-options "['caps:ctrl_modifier']"
