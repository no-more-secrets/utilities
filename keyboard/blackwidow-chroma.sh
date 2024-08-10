#!/bin/bash
set -eo pipefail
# ================================================================
# Preparation steps:
# ================================================================
#
#   1. Install the OpenRazer drivers.
#   $ sudo apt install openrazer-meta openrazer-daemon
#
#   2. Install the CLI tool.
#   $ pip install razer-cli --user
#
#   3. Put yourself in group.
#   $ sudo gpasswd -a dsicilia plugdev
#
#   4. Confirm that daemon is running.
#   $ ps -ef | ag openrazer-daemon
#
#   5. List detected devices.
#   $ razer-cli -l
#
# ================================================================

bar() {
  echo '========================================================================'
}

step() {
  bar
  echo "$1"
  shift
  echo "  $ $@"
  bar
  "$@"
  ret=$?
  echo "exit code: $ret"
  echo
  return $ret
}

# Make sure that all of the above works; this will probably fail
# otherwise.
step 'Listing Supported Devices' \
  razer-cli -l

# Set brightness.
step 'Setting Brightness' \
  razer-cli -b 100

# Set color.
step 'Setting Color' \
  razer-cli -c ff4400  # orange
