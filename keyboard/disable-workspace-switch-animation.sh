#!/bin/bash
# By default, when switching workspaces in gnome, it will animate
# them sliding. This will disable that.
set -eo pipefail

gsettings set org.gnome.desktop.interface enable-animations false
