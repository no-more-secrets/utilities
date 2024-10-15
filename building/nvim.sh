#!/bin/bash
# ---------------------------------------------------------------
# NeoVim
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
project_key="nvim"

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
acct="neovim"
repo="neovim"

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
# Check apt Dependencies
# ---------------------------------------------------------------
# This will install apt packages that are required for the build.
# These were determined empirically, and may change with time
# and/or with Linux distribution. This will be a no-op on OSX.
echo 'You may be asked for your password to install apt dependencies:'
apt_deps="
  gettext
"
echo -e "$apt_deps"

install_if_not_installed "$apt_deps"

# ---------------------------------------------------------------
# Clone Repo
# ---------------------------------------------------------------
clone_latest_tag "$acct" "$repo"
cd $repo

# ---------------------------------------------------------------
# Build
# ---------------------------------------------------------------
unset LUA_PATH
unset LUA_CPATH
unset LUA_INIT

old_lua_version="$(luarocks config lua_version)"
log "setting lua version from $old_lua_version to 5.1 temporarily..."
luarocks config lua_version 5.1

# NeoVim has a CMake-based build, but the directions say to use
# the Makefile, which also appears to do other things like down-
# load third-party dependencies.
make CMAKE_BUILD_TYPE=RelWithDebInfo \
     CMAKE_INSTALL_PREFIX=$prefix    \
     -j$(build_threads)              \
     install

# ---------------------------------------------------------------
# Make Links
# ---------------------------------------------------------------
tools_link $project_key
bin_links $project_key

# ---------------------------------------------------------------
# Restore Lua Version.
# ---------------------------------------------------------------
log "setting lua version back to $old_lua_version."
luarocks config lua_version "$old_lua_version"

# ---------------------------------------------------------------
# Finish
# ---------------------------------------------------------------
log "success."
