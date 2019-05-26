#!/bin/bash
# This script will simply install Rosegarden via `apt` but will
# also place a launcher on the desktop that launches it with an
# environment variable set that tells QT to scale with pixel den-
# sity.
set -e
set -o pipefail

cd "$(dirname "$0")"

sudo apt install rosegarden

cp data/Rosegarden.desktop ~/Desktop
