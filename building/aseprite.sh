#!/bin/bash
# ---------------------------------------------------------------
# Aseprite: Pixel Art Editor
# ---------------------------------------------------------------
# This script will first run the skia-aseprite.sh script to build
# the latest version of skia (which is an aseprite dependency in
# later versions). It will then build the latest tag of aseprite.
set -e
set -o pipefail

# Must be done first.
this=$(cd $(dirname $0) && pwd)
cd $this

# ---------------------------------------------------------------
# Includes
# ---------------------------------------------------------------
source util.sh

# ---------------------------------------------------------------
# Initialization
# ---------------------------------------------------------------
# This must be a lowercase short word with no spaces describing
# the software being built. Folders/links will be named with
# this.
project_key="aseprite"

cd /tmp

work=$project_key-build
[[ -d $work ]] && /bin/rm -rf "$work"
mkdir -p $work && cd $work

tools="$HOME/dev/tools"
mkdir -p "$tools"

# ---------------------------------------------------------------
# Build `skia` if necessary.
# ---------------------------------------------------------------
$this/skia-aseprite.sh

skia_current="$tools/skia-current"
[[ -e "$skia_current" ]] || \
    die "Skia not found (the above script should have built it)."

skia_real_version=$(realpath $skia_current)
log "skia_real_version: $skia_real_version"

# ---------------------------------------------------------------
# Functions
# ---------------------------------------------------------------
latest_github_repo_tag() {
    local acct="$1"
    local repo="$2"
    local api_url="https://api.github.com/repos/$acct/$repo/tags"
    # FROM: "name": "v8.1.0338",
    # TO:   v8.1.0338
    # There's a strange tag called v7_0_2beta that is very old
    # that we don't want (it would otherwise come up because it
    # has the most recent version number by far).
    curl --silent $api_url | grep '"name":'       \
                           | grep -v 'v7_0_2beta' \
                           | head -n1             \
                           | sed 's/.*: "\(.*\)".*/\1/'
}

clone_latest_tag() {
    local acct="$1"
    local repo="$2"
    # non-local
    version=$(latest_github_repo_tag $acct $repo)
    log "latest version of $acct/$repo: $version"
    sleep 3
    git clone --depth=1         \
              --branch=$version \
              --recursive       \
              https://github.com/$acct/$repo
}

# ---------------------------------------------------------------
# Check version and if it already exists.
# ---------------------------------------------------------------
acct="aseprite"
repo="aseprite"

version=$(latest_github_repo_tag $acct $repo)

[[ -e "$tools/$project_key-$version" ]] && {
    log "$project_key-$version already exists, activating it."
    tools_link $project_key
    bin_links $project_key
    exit 0
}

prefix="$tools/$project_key-$version"

# ---------------------------------------------------------------
# Check apt Dependencies
# ---------------------------------------------------------------
# This will check for the presence of (but not install) apt pack-
# ages that are required for the build. These are taken from the
# Aseprite INSTALL.md file, and may change with time.
check_apt_dependencies "
  libx11-dev
  libxcursor-dev
  libgl1-mesa-dev
  libfontconfig1-dev
"

# ---------------------------------------------------------------
# Clone repo
# ---------------------------------------------------------------
clone_latest_tag $acct $repo
cd $repo && mkdir build && cd build

# ---------------------------------------------------------------
# Run CMake
# ---------------------------------------------------------------
# Use the deferenced path for the skia directory because we are
# building against it and so we don't want a given version of
# aseprite to break if the skia-current symlink changes.
cmake .. -DSKIA_DIR=$skia_real_version    \
         -DCMAKE_INSTALL_PREFIX="$prefix" \
         -G Ninja

# ---------------------------------------------------------------
# Build/Test
# ---------------------------------------------------------------
ninja && ninja install

$prefix/bin/aseprite --version

# ---------------------------------------------------------------
# Make symlinks
# ---------------------------------------------------------------
tools_link $project_key
bin_links  $project_key

log "Success."
