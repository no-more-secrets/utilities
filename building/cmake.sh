#!/bin/bash
set -e
set -o pipefail

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

latest_github_repo_tag() {
    local acct_name="$1"
    local repo_name="$2"
    local api_url="https://api.github.com/repos/$acct_name/$repo_name/tags"
    # FROM: "name": "v8.1.0338",
    # TO:   v8.1.0338
    curl --silent $api_url | grep '"name":'            \
                           | head -n1                  \
                           | sed -r 's/.*"(.*)",?/\1/'
}

clone_latest_tag() {
    local acct_name="$1"
    local repo_name="$2"
    # non-local
    version=$(latest_github_repo_tag $acct_name $repo_name)
    echo "Latest version of $acct_name/$repo_name: $version"
    git clone --depth=1 --branch=$version https://github.com/$acct_name/$repo_name
}

clone_latest_tag $acct $repo
cd $repo

tools="$HOME/dev/tools"
mkdir -p "$tools"

prefix="$tools/${repo,,}-$version"

./bootstrap --prefix=$prefix

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
rm -f ~/bin/ctest

ln -s $prefix/bin/cmake ~/bin/cmake
ln -s $prefix/bin/ctest ~/bin/ctest
