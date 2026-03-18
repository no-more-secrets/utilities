#!/bin/bash
# ---------------------------------------------------------------
# taskwarrior
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
project_key="taskwarrior"
bin_name="task"

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
acct="GothenburgBitFactory"
repo="taskwarrior"

version=$(latest_github_repo_tag $acct $repo)

[[ -e "$tools/$project_key-$version" ]] && {
    log "$project_key-$version already exists, activating it."
    tools_link $project_key
    bin_links $project_key $bin_name
    #supplemental_install
    exit 0
}

prefix="$tools/$project_key-$version"
log "latest version: $version"

# ---------------------------------------------------------------
# Install apt Dependencies
# ---------------------------------------------------------------
install_if_not_installed "
  uuid-dev
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
         -DBUILD_TESTS=YES          \
         -DCMAKE_INSTALL_PREFIX=$prefix

# ---------------------------------------------------------------
# Build
# ---------------------------------------------------------------
ninja

# ---------------------------------------------------------------
# Test
# ---------------------------------------------------------------
ninja test_runner # won't get built otherwise, even by ninja test.
ninja test

# ---------------------------------------------------------------
# Install
# ---------------------------------------------------------------
ninja install

# ---------------------------------------------------------------
# Test Run
# ---------------------------------------------------------------
$prefix/bin/task --version

# ---------------------------------------------------------------
# Make Links
# ---------------------------------------------------------------
tools_link $project_key
bin_links $project_key $bin_name

# ---------------------------------------------------------------
# Finish
# ---------------------------------------------------------------
log "success."
