#!/bin/bash
# ---------------------------------------------------------------
# Polybar
# ---------------------------------------------------------------
set -eE
set -o pipefail

# Must be done first.
this=$(cd $(dirname $0) && pwd)
cd $this

# ---------------------------------------------------------------
# Includes
# ---------------------------------------------------------------
source util.sh

# ---------------------------------------------------------------
# Script Dependencies
# ---------------------------------------------------------------
log "Installing the siji font (used by polybar example config)."
./siji.sh
log "Successfully installed siji font."

# ---------------------------------------------------------------
# Initialization
# ---------------------------------------------------------------
# This must be a lowercase short word with no spaces describing
# the software being built. Folders/links will be named with
# this.
project_key="polybar"

tools="$HOME/dev/tools"
mkdir -p "$tools"

# ---------------------------------------------------------------
# Create Work Area
# ---------------------------------------------------------------
cd /tmp

work=$project_key-build

[[ -d $work ]] && /bin/rm -rf "$work"
mkdir -p $work
cd $work

# ---------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------
install_apt_dependencies '
  cargo
  libasound2-dev
  libcairo2-dev
  libcurl4-openssl-dev
  libiw-dev
  libmpdclient-dev
  libpulse-dev
  libxcb-composite0-dev
  libxcb-cursor0
  libxcb-ewmh-dev
  libxcb-icccm4-dev
  libxcb-image0-dev
  libxcb-randr0-dev
  libxcb-util0-dev
  libxcb-xkb-dev
  libxcb-xrm-dev
  pkg-config
  python-xcbgen
  xcb
  xcb-proto
'

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

# ---------------------------------------------------------------
# Check version and if it already exists.
# ---------------------------------------------------------------
acct="polybar"
repo="polybar"

version=$(latest_github_repo_tag $acct $repo)

[[ -e "$tools/$project_key-$version" ]] && {
    log "$project_key-$version already exists, activating it."
    tools_link $project_key
    bin_links $project_key
    #supplemental_install
    exit 0
}

prefix="$tools/$project_key-$version"
log "latest version: $version"

# ---------------------------------------------------------------
# Clone Repo
# ---------------------------------------------------------------
clone_latest_tag "$acct" "$repo"
cd $repo

# ---------------------------------------------------------------
# Configure
# ---------------------------------------------------------------
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo \
         -DCMAKE_INSTALL_PREFIX=$prefix    \
         -G Ninja

# ---------------------------------------------------------------
# Build
# ---------------------------------------------------------------
ninja
ninja install

# ---------------------------------------------------------------
# Make Links
# ---------------------------------------------------------------
tools_link $project_key
bin_links $project_key

# ---------------------------------------------------------------
# Finish
# ---------------------------------------------------------------
log "success."
