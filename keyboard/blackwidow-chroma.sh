#!/bin/bash
# ---------------------------------------------------------------
# Preparation steps.
# ---------------------------------------------------------------
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
# ---------------------------------------------------------------
set -eo pipefail

# ---------------------------------------------------------------
# Modules.
# ---------------------------------------------------------------
source ~/dev/utilities/bashlib/util.sh

# ---------------------------------------------------------------
# Functions.
# ---------------------------------------------------------------
c() {
  echo -en "$@"
}

indent() {
  sed -r 's/^/  /'
}

clip() {
  sed -ru 's/(.{0,'$COLUMNS'}).*/\1/g'
}

bar() {
  local char="$1"
  char=${char:-=}
  local count="$2"
  count=${count:-$COLUMNS}
  c "$c_yellow"
  echo -en "$c_yellow"
  for (( i=0; i < $count; i++ )); do
    echo -n "$char"
  done
  c "$c_norm"
  echo
}

indent_bar() {
  echo -n '  '
  local char="$1"
  char=${char:-=}
  bar "$1" $(( COLUMNS-2 ))
}

razer_cli() {
  c "$c_red"
  echo "  $ razer-cli" "$@"
  c "$c_norm"
  indent_bar -
  c "$c_blue"
  razer-cli -v "$@" | grep -v '^$' | indent | clip
  ret=$?
  c "$c_norm"
  echo "[exit code: $ret]" | indent
}

step() {
  bar
  c "$s_bold"
  echo "$@"
  c "$c_norm"
  bar
}

# ---------------------------------------------------------------
# main.
# ---------------------------------------------------------------
main() {
  # Make sure that all of the above works; this will probably
  # fail otherwise.
  step 'Listing Supported Devices'
  razer_cli -ls

  # Set brightness.
  echo
  step 'Setting Brightness'
  razer_cli -b 100

  # Set color.
  echo
  step 'Setting Color'
  razer_cli -c ff4400  # orange

  # Finished.
  echo
  step 'Finished.'
}

main "$@"
