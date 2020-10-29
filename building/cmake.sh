#!/bin/bash
set -eE
set -o pipefail

# Must be done first.
this=$(cd $(dirname $0) && pwd)
cd $this

# ---------------------------------------------------------------
# Includes
# ---------------------------------------------------------------
source util.sh

cd /tmp

work=cmake-build

[[ -d $work ]] && /bin/rm -rf "$work"
mkdir -p $work
cd $work

die() {
  echo "$@" >&2
  exit 1
}

acct="Kitware"
repo="CMake"
# The ${X,,} construct doesn't seem to work on OSX's bash
repo_lower="cmake"
project_key="$repo_lower"
tools="$HOME/dev/tools"

latest_github_repo_tag() {
    local acct_name="$1"
    local repo_name="$2"
    local api_url="https://api.github.com/repos/$acct_name/$repo_name/tags"
    # FROM: "name": "v8.1.0338",
    # TO:   v8.1.0338
    curl --silent $api_url | grep '"name":'            \
                           | head -n1                  \
                           | sed 's/.*: "\(.*\)".*/\1/'
}

clone_latest_tag() {
    local acct_name="$1"
    local repo_name="$2"
    # non-local
    echo "Latest version of $acct_name/$repo_name: $version"
    git clone --depth=1 --branch=$version https://github.com/$acct_name/$repo_name
}

version=$(latest_github_repo_tag $acct $repo)

[[ -e "$tools/$project_key-$version" ]] && {
    log "$project_key-$version already exists, activating it."
    tools_link $project_key
    bin_links $project_key
    #supplemental_install
    exit 0
}

clone_latest_tag $acct $repo
cd $repo

mkdir -p "$tools"

prefix="$tools/${repo_lower}-$version"

if which cmake; then
    # Use system curl library so that we can install the one with
    # SSL support and have CMake use that. This then appears to
    # avoid errors that would otherwise happen when CMake tries
    # to download using https links.
    cmake .                                 \
        -DCMAKE_INSTALL_PREFIX=$prefix      \
        -DCMAKE_USE_SYSTEM_LIBRARY_CURL=YES
else
    ./bootstrap --prefix=$prefix --system-curl
fi

if which nproc 2>/dev/null; then
    threads=$(nproc --all)
else
    threads=4
fi

make -j$threads
make install

$prefix/bin/cmake --version

mkdir -p ~/bin

rm -f ~/bin/cmake
rm -f ~/bin/ccmake
rm -f ~/bin/ctest

cmake_current="$tools/cmake-current"
rm -f "$cmake_current"

ln -s $prefix $tools/cmake-current
ln -s $cmake_current/bin/cmake  ~/bin/cmake
ln -s $cmake_current/bin/ccmake ~/bin/ccmake
ln -s $cmake_current/bin/ctest  ~/bin/ctest
