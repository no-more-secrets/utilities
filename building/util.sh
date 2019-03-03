#!/bin/bash
# This file contains bash utilities for use by the build scripts.

c_norm="\033[00m"
c_green="\033[32m"
c_green="\033[32m"
c_red="\033[31m"

log() {
    echo -e "[$(date)] ${c_green}INFO${c_norm} $*"
}

error() {
    echo -e "[$(date)] ${c_red}ERROR${c_norm} $*" >&2
}

die() {
  error "$*"
  exit 1
}

# This is for compatibility between linux/osx.
real_path() {
  if which grealpath &>/dev/null; then
      grealpath "$@"
  else
      realpath "$@"
  fi
}

# Creates a symlink in the ~/bin folder to the current version of
# the tool.  Note: it assumes that the link name will be the same
# as the binary name and that the binary is located in:
#
#   $tools/<tool-name>/bin/$1
#
bin_links() {
    [[ -z "$tools" ]] && \
        die "the 'tools' variable must be set in bin_links."
    [[ -d "$tools" ]] || \
        die "the 'tools' folder ($tools) must exist."
    local what="$1"
    mkdir -p ~/bin
    rm -f ~/bin/$what
    ln -s $tools/$what-current/bin/$what ~/bin/$what
}

# Creates link in the tools folder to the current version of a
# tool.
tools_link() {
    [[ -z "$tools" ]] && \
        die "the 'tools' variable must be set in tools_link."
    [[ -d "$tools" ]] || \
        die "the 'tools' folder ($tools) must exist."
    local what="$1"
    pushd $tools &>/dev/null
    rm -f $what-current
    ln -s $what-$version $what-current
    popd &>/dev/null
}

is_package_installed() {
  apt list --installed "$1" 2>/dev/null | grep '\[installed\]'
}

check_apt_dependencies() {
  # If we're not on linux then do nothing here.
  [[ "$(uname)" == Linux ]] || return 0
  local list="$1"
  for package in $list; do
    log "checking for apt dependency $package..."
    if ! is_package_installed $package; then
        die "You need to install the '$package' package."
    fi
  done
  return 0
}
