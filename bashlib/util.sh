#!/bin/bash
# This file contains bash utilities for general use.

c_norm="\033[00m"
c_green="\033[32m"
c_red="\033[31m"
c_blue="\033[34m"
c_yellow="\033[93m"
s_bold="\033[1m"
s_under="\033[4m"

log_stamp() { echo -e "[$(date)] ${c_green}info${c_norm} $*"; }

log()       { echo -e "${c_green}info${c_norm} $*"; }
debug()     { echo -e "${c_blue}debug${c_norm} $*"; }
warn()      { echo -e "${c_yellow}warn${c_norm} $*"; }

error_stamp() { echo -e "[$(date)] ${c_red}error${c_norm}: $*" >&2; }
error()       { echo -e "${c_red}error${c_norm}: $*" >&2; }
die()         { error "$*"; exit 1; }

# This is for compatibility between linux/osx.
real_path() {
  if which grealpath &>/dev/null; then
      grealpath "$@"
  else
      realpath "$@"
  fi
}

build_threads() {
  local threads=4
  if [[ "$(uname)" == Linux ]]; then
    threads=$(nproc --all)
  elif [[ "$(uname)" == Darwin ]]; then
    threads=$(sysctl -n hw.ncpu)
  fi
  [[ -z "$threads" ]] && return 1
  echo "$threads"
  return 0
}

# A script should pass the $0 argument to this function.
cd_to_this() {
  local dollar_0=$1
  [[ -z "$dollar_0" ]] && \
    die "argument to cd_to_this is empty."
  this="$(dirname "$(readlink -f $dollar_0)")"
  cd "$this"
}

# Given a stream of lines on stdin, this will chunk them (trans-
# pose them) into n columns (n is first arg).
#
# Sample input:
#
#   <line 1>
#   <line 2>
#   <line 3>
#   <line 4>
#   <line 5>
#   <line 6>
#   <line 7>
#
# Output of `transpose 2`:
#
#   <line 1> <line 2>
#   <line 3> <line 4>
#   <line 5> <line 6>
#   <line 7>
#
transpose() {
  local n=$1
  [[ -z "$n" ]] && die "missing argument to transpose."
  (( n == 0 ))  && die "passed 0 to transpose."
  # xargs default's to `echo` when no command is specified.
  xargs -n$n -d'\n'
}

clear_current_line() {
  echo -en "\033[2K"
}

clear_to_eol() { tput el; }

move_up_one_line() {
  echo -en "\033[A"
}
