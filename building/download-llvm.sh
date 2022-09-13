#!/bin/bash
# This script will find the latest Linux64 Ubuntu release binary
# of the LLVM package and will downloade it and untar it, but
# only if there is not llvm-current link in the tools folder.
#
# It is meant to bootstrap a clang-PGO build since the gcc on the
# system sometimes cannot build LLVM due to ICEs or various other
# issues.
set -e
set -o pipefail
# set -x

tools=~/dev/tools
mkdir -p "$tools"
cd "$tools"

[[ -e llvm-current ]] && {
  echo "There is already an llvm, no need to download one."
  exit 1
}

latest_llvm_tarball_stem() {
  curl -s https://api.github.com/repos/llvm/llvm-project/releases \
    | grep -E 'clang\+llvm-.*-x86_64-linux-gnu-ubuntu-.*tar.xz",' \
    | head -n1                                                    \
    | sed -r 's/\s*"name": "(.*)\.tar\.xz",/\1/g'
}

latest_llvm_tarball_version() {
  latest_llvm_tarball_stem | sed -r 's/.*llvm-(.*)-x86_64.*/\1/'
}

release_name="$(latest_llvm_tarball_stem)"
echo "latest llvm tarball release name: $release_name"
[[ ! -z "$release_name" ]]
filename="$release_name.tar.xz"
echo "latest llvm tarball file name:    $filename"
[[ ! -z "$filename" ]]
version=$(latest_llvm_tarball_version)
echo "latest llvm tarball version:      $version"
[[ ! -z "$version" ]]

[[ -d "$release_name" ]] && {
  echo "release $release_name already exists."
  rm -f llvm-downloaded
  ln -s "$release_name" llvm-downloaded
  exit 0
}

echo

[[ ! -d "$release_name" ]]
rm -f clang+llvm*.xz
url="https://github.com/llvm/llvm-project/releases/download/llvmorg-$version/$filename"
echo "Downloading: $url"
wget "$url"
[[ -e "$filename" ]]

tar xvf "$filename"
rm clang+llvm*.xz
rm -f llvm-downloaded
[[ -d "$release_name" ]]
ln -s "$release_name" llvm-downloaded
ln -s "$release_name" llvm-current
