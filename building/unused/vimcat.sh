#!/bin/bash
# This script will query github for the latest tag of vimcat,
# clone the repo, checkout the release tag, then install.
set -e

repo_acct='vim-scripts'
repo_name='vimcat'
github_repo="https://github.com/$repo_acct/$repo_name.git"
api_repo="https://api.github.com/repos/$repo_acct/$repo_name/tags"

echo "getting latest $repo_name version:"
# FROM: "name": "v8.1.0338",
# TO:   v8.1.0338
version=$(curl --silent $api_repo | grep name | head -n1 | sed 's/.*: "\(.*\)".*/\1/')

echo found: $version

cd /tmp

work_dir="$repo_name"
[[ -d "$work_dir" ]] && rm -rf "$work_dir"
mkdir "$work_dir"
cd "$work_dir"

git clone --depth=1 --branch=$version $github_repo

cd $work_dir

tools="$HOME/dev/tools"
mkdir -p "$tools"

prefix="$tools/$repo_name-$version"

echo prefix: $prefix
mkdir -p "$prefix"

cp vimcat "$prefix/"
chmod u+x "$prefix/vimcat"

rm -f ~/bin/vimcat

mkdir -p ~/bin

pushd "$tools"
rm -f vimcat-current
ln -s vimcat-$version vimcat-current
popd

ln -s $tools/vimcat-current/vimcat ~/bin/vimcat
