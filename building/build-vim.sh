#!/bin/bash
# This script will query github for the latest tag of vim, clone
# the repo, checkout the release tag, then configure and build,
# then install into a user folder.  Finally, it makes a symlink
# in ~/bin/vim to the new vim binary.  This script can be run
# also to update vim, since a new version of vim will be installed
# into a folder with the version number of vim.
set -e

vim_repo='https://api.github.com/repos/vim/vim/tags'

echo getting latest vim version:
# FROM: "name": "v8.1.0338",
# TO:   8.1.0338
version=$(curl --silent $vim_repo | grep name | head -n1 | sed -r 's/.*v([^"]+)".*/\1/')
echo found: $version

cd /tmp

[[ -d vim ]] && rm -rf vim

git clone --depth=1 --branch=v$version https://github.com/vim/vim

cd vim

tools="$HOME/dev/tools"
mkdir -p "$tools"

prefix="$tools/vim-$version"

./configure --enable-python3interp=yes --prefix=$prefix

make -j8

make install

$prefix/bin/vim --version

rm -f ~/bin/vim
rm -f ~/bin/vimdiff

mkdir -p ~/bin

ln -s $prefix/bin/vim ~/bin/vim
ln -s $prefix/bin/vimdiff ~/bin/vimdiff
