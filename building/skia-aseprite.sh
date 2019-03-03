#!/bin/bash
# ---------------------------------------------------------------
# Skia: cross-platform basic 2D graphics library
# ---------------------------------------------------------------
# This script will build the version of `skia` used as a depen-
# dency by Aseprite and install it to the tools folder. It is a
# bit large -- 2GB -- on account of the third_party folder that
# it contains (which we cannot remove because it is required to
# build Aseprite). So therefore old versions should be removed.
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
project_key="skia"

cd /tmp

work=$project_key-build
[[ -d $work ]] && /bin/rm -rf "$work"
mkdir -p $work && cd $work

tools="$HOME/dev/tools"
mkdir -p "$tools"

# ---------------------------------------------------------------
# Functions
# ---------------------------------------------------------------
latest_github_repo_branch() {
    local acct="$1"
    local repo="$2"
    local api_url="https://api.github.com/repos/$acct/$repo/branches"
    # FROM: "name": "v8.1.0338",
    # TO:   v8.1.0338
    curl --silent $api_url | grep '"name":'             \
                           | grep 'aseprite-m[0-9]\+"'  \
                           | sed 's/.*: "\(.*\)".*/\1/' \
                           | sort -rV                   \
                           | head -n1
}

clone_latest_branch() {
    local acct="$1"
    local repo="$2"
    # non-local
    version=$(latest_github_repo_branch $acct $repo)
    log "latest version of $acct/$repo: $version"
    sleep 3
    git clone --depth=1         \
              --branch=$version \
              --recursive       \
              https://github.com/$acct/$repo
}

# ---------------------------------------------------------------
# Check version
# ---------------------------------------------------------------
acct="aseprite"
repo="skia"

version=$(latest_github_repo_branch $acct $repo)

[[ -e "$tools/$project_key-$version" ]] && {
    log "$project_key-$version already exists, activating it."
    tools_link $project_key
    exit 0
}

# ---------------------------------------------------------------
# Clone depo_tools
# ---------------------------------------------------------------
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

# This is needed for the `gn` tool below.
export PATH="$PWD/depot_tools:$PATH"

# ---------------------------------------------------------------
# Clone aseprite-skia repo and dependencies
# ---------------------------------------------------------------
clone_latest_branch $acct $repo

cd skia

python tools/git-sync-deps

# ---------------------------------------------------------------
# Configure
# ---------------------------------------------------------------
gn gen out/Release --args="
    is_debug=false
    is_official_build=true
    skia_use_system_expat=false
    skia_use_system_icu=false
    skia_use_system_libjpeg_turbo=false
    skia_use_system_libpng=false
    skia_use_system_libwebp=false
    skia_use_system_zlib=false
"

# ---------------------------------------------------------------
# Build
# ---------------------------------------------------------------
ninja -C out/Release skia

# ---------------------------------------------------------------
# Install/Copy
# ---------------------------------------------------------------
cd ..

prefix="$tools/$project_key-$version"

# The `gn` tools doesn't seem to have an install feature, so we
# just install by copying it.
mv skia $prefix

# ---------------------------------------------------------------
# Create Symlinks
# ---------------------------------------------------------------
tools_link $project_key
