#!/bin/bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Lua
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set -e
set -o pipefail

# ---------------------------------------------------------------
# Includes
# ---------------------------------------------------------------
source util.sh

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Find Latest Version
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
lua_site="https://www.lua.org/ftp"

version=$(wget -qO- "$lua_site/" -o /dev/null     \
            | grep -o 'lua-[0-9]\+\.[0-9]\+\.[0-9]\+\.tar\.gz'  \
            | sed 's/lua-\(.*\)\.tar\.gz/\1/'                   \
            | sort -Vu                                          \
            | tail -n1                                          \
)

log "latest version: $version"

[[ -z "$version" ]] && die "could not find version number."

# ---------------------------------------------------------------
# Folders
# ---------------------------------------------------------------
project_key=lua

tools="$HOME/dev/tools"
mkdir -p "$tools"
prefix="$tools/$project_key-$version"

# ---------------------------------------------------------------
# Check version and if it already exists.
# ---------------------------------------------------------------
[[ -e "$prefix" ]] && {
    log "$prefix already exists, activating it."
    tools_link $project_key
    bin_links $project_key
    # Custom links.
    rm -f ~/bin/luac
    ln -s $prefix/bin/luac ~/bin/luac
    exit 0
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create Work Area
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
cd /tmp

work=$project_key-build

[[ -d $work ]] && /bin/rm -rf "$work"
mkdir -p $work
cd $work

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Download tar file
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
curl -sSfO "$lua_site/lua-$version.tar.gz"
tar xvf lua-$version.tar.gz
cd lua-$version

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Setup make vars
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[[ "$(uname)" == Linux ]] && plat=linux || plat=macosx

flags="
  PLAT=$plat
  INSTALL_TOP=$prefix
"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Run Make
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
make all     -j$(build_threads) $flags
make install -j$(build_threads) $flags

# ---------------------------------------------------------------
# Make symlinks
# ---------------------------------------------------------------
tools_link $project_key
bin_links  $project_key

# Custom links.
rm -f ~/bin/luac
ln -s $prefix/bin/luac ~/bin/luac

log "Success."
