#!/bin/bash
# ---------------------------------------------------------------
# lazygit
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
project_key="lazygit"

tools="$HOME/dev/tools"
mkdir -p "$tools"

# ---------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------
export GOPATH=~/dev/go

install_apt_dependencies '
  golang
'

# ---------------------------------------------------------------
# Build
# ---------------------------------------------------------------
go get github.com/jesseduffield/lazygit
prefix=$tools/$project_key
mkdir -p $prefix/bin
cp $GOPATH/bin/lazygit $prefix/bin

# ---------------------------------------------------------------
# Make Links
# ---------------------------------------------------------------
rm -f $tools/lazygit-current
ln -s $tools/lazygit $tools/lazygit-current
bin_links $project_key

# ---------------------------------------------------------------
# Finish
# ---------------------------------------------------------------
log "success."
