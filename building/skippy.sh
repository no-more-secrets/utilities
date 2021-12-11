#!/bin/bash
# ---------------------------------------------------------------
# Skippy-xd
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
project_key="skippy-xd"

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
clone_master() {
    local acct="$1"
    local repo="$2"
    local version=master
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
acct="richardgv"
repo="skippy-xd"

version=master

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
# Check apt Dependencies
# ---------------------------------------------------------------
# This will install apt packages that are required for the build.
# These were determined empirically, and may change with time
# and/or with Linux distribution. This will be a no-op on OSX.
echo 'You may be asked for your password to install apt dependencies:'
apt_deps="
  libjpeg-dev
  libgif-dev
"
echo -e "$apt_deps"

install_if_not_installed "$apt_deps"

# ---------------------------------------------------------------
# Clone Repo
# ---------------------------------------------------------------
clone_master "$acct" "$repo"
cd $repo

# ---------------------------------------------------------------
# Build
# ---------------------------------------------------------------
make DESTDIR=$prefix -j$(build_threads) install

# ---------------------------------------------------------------
# Make Links
# ---------------------------------------------------------------
tools_link $project_key
bin_links $project_key

cd "$prefix"
ln -s usr/bin bin

# ---------------------------------------------------------------
# Finish
# ---------------------------------------------------------------
log "success."
