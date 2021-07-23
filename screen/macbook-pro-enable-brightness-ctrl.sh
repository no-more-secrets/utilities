#!/bin/bash
# This command will enable Linux to control the brightness of the
# MacBook Pro display.  Taken from here:
#
#   https://askubuntu.com/questions/370857/cant-adjust-screen-brightness-on-macbook-pro-10-1-ubuntu-13-10

set -e
set -o pipefail

sudo setpci -v -H1 -s 00:01.00 BRIDGE_CONTROL=0