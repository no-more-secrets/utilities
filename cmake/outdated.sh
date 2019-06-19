#!/bin/bash
# Print a list of non-hidden files that have been modified since
# the last build.
set -e

current=".builds/current"

c_norm="\033[00m"
c_green="\033[32m"
c_red="\033[31m"
s_bold="\033[1m"
s_under="\033[4m"
c_yellow="\033[93m"

[[ -e "$current" ]] || {
  echo 'no configurations!' 1>&2
  exit 1
}

stamp="$current/last-build-stamp"

[[ -f "$stamp" ]] || exit 0

[[ "$1" == "-v" ]] && verbose=1 || verbose=0

files="$(find . -not -name '.*' -not -wholename '*/.*' -type f -newer "$stamp" | sed 's|^./||')"

[[ -z "$files" ]] && exit 0

(( verbose )) && {
  echo -e "*** ${c_yellow}${s_bold}files changed $c_norm***********************************************"
  echo -en "$c_red"
}

echo -e "$files"

(( verbose )) && {
  echo -en "$c_norm"
  echo "*****************************************************************"
}

true
