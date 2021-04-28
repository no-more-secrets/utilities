#!/bin/bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tmux
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
project_key=tmux
bin_name=tmux

tools="$HOME/dev/tools"
mkdir -p "$tools"
prefix="$tools/$project_key-$version"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Find Latest Version
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
acct="tmux"
repo="tmux"

api_url="https://api.github.com/repos/$acct/$repo/tags"
# FROM: "name": "v3.9.2",
# TO:   v3.9.2
# Pick most recent version, but skipping release candidates.
version=$(curl --silent $api_url | grep '"name":'   \
                       | sed 's/.*: "\(.*\)".*/\1/' \
                       | grep '^[0-9]'              \
                       | head -n1)

log "latest version: $version"
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

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Install Dependencies
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
install_if_not_installed "
  libevent-dev
"

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
./autogen.sh
./configure --prefix=$prefix

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Run Make
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
make all     -j$(build_threads)
make install -j$(build_threads)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Test Run
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
log "running protoc:"
$prefix/bin/tmux -V

# ---------------------------------------------------------------
# Make symlinks
# ---------------------------------------------------------------
tools_link $project_key
bin_links  $project_key $bin_name

log "Success."
