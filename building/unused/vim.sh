#!/bin/bash
# ---------------------------------------------------------------
# vim
# ---------------------------------------------------------------
set -eEo pipefail

# ---------------------------------------------------------------
# Includes.
# ---------------------------------------------------------------
source ~/dev/utilities/building/util.sh

tools="$HOME/dev/tools"
mkdir -p "$tools"

# ---------------------------------------------------------------
# Get Latest Version.
# ---------------------------------------------------------------
vim_repo='https://api.github.com/repos/vim/vim/tags'

log_no_newline "Getting latest vim version: "
# FROM: "name": "v8.1.0338",
# TO:   v8.1.0338
version=$(curl --silent $vim_repo | grep name | head -n1 | sed 's/.*: "\(.*\)".*/\1/')

echo -e "${c_yellow}$version${c_norm}"

activate() {
  mkdir -p ~/bin
  rm -f ~/bin/vim

  pushd "$tools" >/dev/null
  rm -f vim-current
  ln -s vim-$version vim-current
  popd >/dev/null

  ln -s $tools/vim-current/bin/vim ~/bin/vim
}

# ---------------------------------------------------------------
# Check version.
# ---------------------------------------------------------------
if [[ -e "$tools/vim-$version" ]]; then
  log "vim-$version already exists, activating it."
  activate
  exit 0
fi

# ---------------------------------------------------------------
# Check Python.
# ---------------------------------------------------------------
echo looking for python3
if ! which python3; then
    echo You must have python3 installed otherwise the vim
    echo configure step would silently avoid enabling support
    echo for it in the vim build.
    exit 1
fi

# ---------------------------------------------------------------
# Clone.
# ---------------------------------------------------------------
cd /tmp
[[ -d vim ]] && rm -rf vim

git clone --depth=1 --branch=$version https://github.com/vim/vim

# ---------------------------------------------------------------
# Configure.
# ---------------------------------------------------------------
cd /tmp/vim

install_prefix="$tools/vim-$version"
./configure --enable-python3interp=yes --prefix=$install_prefix

# ---------------------------------------------------------------
# Build.
# ---------------------------------------------------------------
make -j16

# ---------------------------------------------------------------
# Install.
# ---------------------------------------------------------------
make install

# ---------------------------------------------------------------
# Test.
# ---------------------------------------------------------------
$install_prefix/bin/vim --version

# ---------------------------------------------------------------
# Activate links.
# ---------------------------------------------------------------
activate
