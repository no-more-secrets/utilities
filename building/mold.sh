#!/bin/bash
# ---------------------------------------------------------------
# mold
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
# Initialization
# ---------------------------------------------------------------
# This must be a lowercase short word with no spaces describing
# the software being built. Folders/links will be named with
# this.
project_key="mold"
bin_name="mold"

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
acct="rui314"
repo="mold"

version=$(latest_github_repo_tag $acct $repo)

[[ -e "$tools/$project_key-$version" ]] && {
    log "$project_key-$version already exists, activating it."
    tools_link $project_key
    bin_links $project_key $bin_name
    bin_links $project_key ld.mold  # what the compiler invokes.
    #supplemental_install
    exit 0
}

prefix="$tools/$project_key-$version"
log "latest version: $version"

# ---------------------------------------------------------------
# Install apt Dependencies
# ---------------------------------------------------------------
# This package apparently is capable of building a bundled tbb
# library itself and linking it into the binary (which it does by
# default), but that causes a CMake warning to be emitted saying
# that building libtbb statically is highly discouraged, so we
# tell the mold build to use the one on the system.
install_if_not_installed "
  libtbb-dev
  libzstd-dev
"

# ---------------------------------------------------------------
# Clone Repo
# ---------------------------------------------------------------
clone_latest_tag "$acct" "$repo"
cd $repo

# ---------------------------------------------------------------
# Configure
# ---------------------------------------------------------------
mkdir build
cd build
run_cmake ..                        \
         -G Ninja                   \
         -DCMAKE_BUILD_TYPE=Release \
         -DMOLD_USE_SYSTEM_TBB=ON   \
         -DBUILD_TESTING=YES        \
         -DCMAKE_INSTALL_PREFIX=$prefix

# ---------------------------------------------------------------
# Build
# ---------------------------------------------------------------
ninja

# ---------------------------------------------------------------
# Test
# ---------------------------------------------------------------
ninja test

# ---------------------------------------------------------------
# Install
# ---------------------------------------------------------------
ninja install

# ---------------------------------------------------------------
# Test Run
# ---------------------------------------------------------------
$prefix/bin/mold --version

# ---------------------------------------------------------------
# Make Links
# ---------------------------------------------------------------
tools_link $project_key
bin_links $project_key $bin_name
bin_links $project_key ld.mold  # what the compiler invokes.

# ---------------------------------------------------------------
# Finish
# ---------------------------------------------------------------
log "success."
