#!/bin/bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FlatBuffers
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set -e
set -o pipefail

# ---------------------------------------------------------------
# Includes
# ---------------------------------------------------------------
source util.sh

# ---------------------------------------------------------------
# Folders
# ---------------------------------------------------------------
project_key=flatbuffers
bin_name=flatc

tools="$HOME/dev/tools"
mkdir -p "$tools"
prefix="$tools/$project_key-$version"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Find Latest Version
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
acct="google"
repo="flatbuffers"

api_url="https://api.github.com/repos/$acct/$repo/tags"
# FROM: "name": "v3.9.2",
# TO:   v3.9.2
# Pick most recent version, but skipping release candidates.
version=$(curl --silent $api_url | grep '"name":'   \
                       | sed 's/.*: "\(.*\)".*/\1/' \
                       | head -n1)

[[ -z "$version" ]] && die "could not find version number."

# ---------------------------------------------------------------
# Check version and if it already exists.
# ---------------------------------------------------------------
prefix="$tools/$project_key-$version"

[[ -e "$prefix" ]] && {
    log "$project_key-$version already exists, activating it."
    tools_link $project_key
    bin_links $project_key $bin_name
    #supplemental_install
    exit 0
}

log "latest version: $version"
sleep 3

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create Work Area
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
cd /tmp

work=$project_key-build

[[ -d $work ]] && /bin/rm -rf "$work"
mkdir -p $work
cd $work

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Clone Repo
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
git clone --depth=1         \
          --branch=$version \
          --recursive       \
          https://github.com/$acct/$repo

cd $repo

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Configure
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mkdir build && cd build

cmake ..                               \
     -DCMAKE_BUILD_TYPE=RelWithDebInfo \
     -DCMAKE_INSTALL_PREFIX=$prefix    \
     -G Ninja                          \

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Build
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ninja
ninja test
ninja install

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Test Run
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
log "running flatc:"
$prefix/bin/flatc --version

# ---------------------------------------------------------------
# Make symlinks
# ---------------------------------------------------------------
tools_link $project_key
bin_links  $project_key $bin_name

log "Success."
