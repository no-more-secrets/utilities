#!/bin/bash
set -e

# 1. Edit /etc/dconf/db/site.d/locks/screensaver and remove all
#    the lines containing "idle-delay".
# 2. sudo dconf update
# 3. Run this script.

echo "You may be asked for your password:"

sudo true

clear
sudo /home/dsicilia/.local/bin/idle-delay-exe
