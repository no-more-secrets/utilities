#!/bin/bash
# ---------------------------------------------------------------
# Aseprite: Pixel Art Editor
# ---------------------------------------------------------------
# This script will build and install LMMS.
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
project_key="lmms"

cd /tmp

work=$project_key-build
[[ -d $work ]] && /bin/rm -rf "$work"
mkdir -p $work && cd $work

tools="$HOME/dev/tools"
mkdir -p "$tools"

# ---------------------------------------------------------------
# Functions
# ---------------------------------------------------------------
latest_github_repo_tag() {
    local acct="$1"
    local repo="$2"
    local api_url="https://api.github.com/repos/$acct/$repo/tags"
    # FROM: "name": "v8.1.0338",
    # TO:   v8.1.0338
    curl --silent $api_url | grep '"name":'       \
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

supplemental_install() {
    supp_inst="$this/install-data/$project_key/install"
    #log "Running supplemental install script for $project_key"
    #"$supp_inst"
}

# ---------------------------------------------------------------
# Check version and if it already exists.
# ---------------------------------------------------------------
acct="LMMS"
repo="lmms"

version=$(latest_github_repo_tag $acct $repo)

[[ -e "$tools/$project_key-$version" ]] && {
    log "$project_key-$version already exists, activating it."
    tools_link $project_key
    bin_links $project_key
    supplemental_install
    exit 0
}

prefix="$tools/$project_key-$version"

# ---------------------------------------------------------------
# Check apt Dependencies
# ---------------------------------------------------------------
# This will install apt packages that are required for the build.
# These are taken from the repo documentation, and may change
# with time. This will be a no-op on OSX.
echo 'You may be asked for your password to install apt dependencies:'
apt_deps="
  alsa-base
  fluid
  fluidsynth
  libfftw3-3
  libfftw3-dev
  libfltk1.3
  libfltk1.3-dev
  libfluidsynth1
  libfluidsynth-dev
  libogg0
  libogg-dev
  libportaudio2
  libportaudiocpp0
  libqt5x11extras5-dev
  libsamplerate0
  libsamplerate0-dev
  libsndfile1
  libsndfile-dev
  libsoundio1
  libsoundio-dev
  libvorbis0a
  libvorbis-dev
  libx11-xcb1
  libx11-xcb-dev
  libxcb-keysyms1
  libxcb-keysyms1-dev
  libxcb-util1
  libxcb-util-dev
  qt5-default
  qtbase5-private-dev
  qttools5-dev
  qttools5-dev-tools
"
echo -e "$apt_deps"

install_apt_dependencies "$apt_deps"

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
cmake .. -DCMAKE_INSTALL_PREFIX="$prefix"  \
         -DCMAKE_BUILD_TYPE=RelWithDebInfo \
         -DWANT_QT5=ON                     \
         -G Ninja

# ---------------------------------------------------------------
# Build/Test
# ---------------------------------------------------------------
ninja
ninja install

#$prefix/bin/aseprite --version

# ---------------------------------------------------------------
# Supplemental Installation Steps
# ---------------------------------------------------------------
supplemental_install

# ---------------------------------------------------------------
# Make symlinks
# ---------------------------------------------------------------
tools_link $project_key
bin_links  $project_key

log "Success."
