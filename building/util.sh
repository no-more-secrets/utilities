#!/bin/bash
# This file contains bash utilities for use by the build scripts.

c_norm="\033[00m"
c_green="\033[32m"
c_red="\033[31m"
c_yellow="\033[93m"

log() {
    echo -e "[$(date)] ${c_green}INFO${c_norm} $*"
}

log_no_newline() {
    echo -en "[$(date)] ${c_green}INFO${c_norm} $*"
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

# CMake seems to rely on the CMAKE_SYSTEM_PREFIX_PATH variable to
# find packages on the system with find_package and the like.
# Somehow it cannot deduce these directories on its own, at least
# on some distros. Also, there doesn't seem to be an environment
# variable that we can set to give it this info, so we have to
# provide it on the command line. There is also
# CMAKE_PREFIX_PATH, but that is supposed to be project-specific
# and set within the project CMakeLists.txt files, so we will set
# the system one instead which is used to build the final set of
# prefix paths.
make_cmake_system_prefix_path() {
  local system_prefix_path='/'
  local paths='
    /usr/lib/x86_64-linux-gnu/cmake
    /usr/lib/x86_64-linux-gnu
  '
  for path in $paths; do
    system_prefix_path="$system_prefix_path;$path"
  done
  echo "$system_prefix_path"
}

# Will run cmake but will first emit the command to be run in a
# text file in the current directory. This should be used in all
# of the build scripts to run cmake instead of a bare cmake com-
# mand.
run_cmake() {
  local CMAKE_SYSTEM_PREFIX_PATH=""
  local out="cmake-commmand.sh"
  echo '#!/bin/bash
set -e

this="$(dirname "$(readlink -f $0)")"
cd "$this"

# NOTE: the CMAKE_SYSTEM_PREFIX_PATH has been appended by the
#       run_cmake bash function that generated this script.
cmake \' > "$out"
  for param in "$@"; do
    echo "  $param \\" >> "$out"
  done
  echo '  -DCMAKE_SYSTEM_PREFIX_PATH="'"$(make_cmake_system_prefix_path)"'"' >> "$out"
  chmod u+x "$out"
  bash "$out"
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
    local project_key="$1"
    [[ -z "$2" ]] && exe=$project_key || exe=$2
    mkdir -p ~/bin
    rm -f ~/bin/$exe
    ln -s $tools/$project_key-current/bin/$exe ~/bin/$exe
}

# Creates link in the tools folder to the current version of a
# tool.
tools_link() {
    [[ -z "$tools" ]] && \
        die "the 'tools' variable must be set in tools_link."
    [[ -d "$tools" ]] || \
        die "the 'tools' folder ($tools) must exist."
    [[ -z "$version" ]] && \
        die "the 'version' variable must be set."
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

install_apt_dependencies() {
  # If we're not on linux then do nothing here.
  [[ "$(uname)" == Linux ]] || return 0
  local list="$1"
  sudo apt install $list --yes
}

install_if_not_installed() {
  # If we're not on linux then do nothing here.
  [[ "$(uname)" == Linux ]] || return 0
  local list="$1"
  for package in $list; do
    log "checking for apt dependency $package..."
    if ! is_package_installed $package; then
      sudo apt install $package --yes
    fi
  done
  return 0
}

post_install_message() {
  echo -e "${c_green}+==================================================================+${c_norm}"
  echo -e "${c_green}|${c_norm} Post-Installation Notes/Instructions                             ${c_green}|${c_norm}"
  echo -e "${c_green}+==================================================================+${c_norm}"

  while true; do
      read line || break
      line="$line                                                                              "
      local regex="^(.{65}).*"
      [[ "$line" =~ $regex ]]
      line="${BASH_REMATCH[1]}"
      echo -e "${c_green}|${c_norm} $line${c_green}|${c_norm}"
  done <<< "$1"

  echo -e "${c_green}+==================================================================+${c_norm}"
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
