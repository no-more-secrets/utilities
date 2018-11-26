#!/bin/bash
set -e
set -o pipefail

cd /tmp

work=iwyu-build

[[ -d $work ]] && /bin/rm -rf "$work"
mkdir -p $work
cd $work

die() {
  echo "$@" >&2
  exit 1
}

acct="include-what-you-use"
repo="include-what-you-use"

revision_number_for_master() {
    # When we are building the master branch (as opposed to a tag)
    # then we will use the output of this function to represent a
    # version number.  We need a version number so that we can put
    # it in the folder name upon installation.  When building tags
    # we use the tag name as the version.  The "version number"
    # obtained in this function is not guaranteed (theoretically)
    # to be unique for two distinct git branches or tags, but so
    # long as we are on master, it is guaranteed to be unique for
    # any commit to master that is pushed publicly, assuming that
    # there are no force-push's on master.
    #
    # IMPORTANT: The catch here is that, to use this, the repo must
    # be cloned with full depth.
    git rev-list --count master
}

latest_github_repo_tag() {
    local acct_name="$1"
    local repo_name="$2"
    local api_url="https://api.github.com/repos/$acct_name/$repo_name/tags"
    # FROM: "name": "v8.1.0338",
    # TO:   v8.1.0338
    curl --silent $api_url | grep '"name":'            \
                           | head -n1                  \
                           | sed -r 's/.*: "(.*)".*/\1/'
}

clone_latest_tag() {
    local acct_name="$1"
    local repo_name="$2"
    local master="$3" # 0/1
    if (( master )); then
        # Instead of fetching the latest tag the user has
        # requested master. This may be required because the
        # latest iwyu tag may not include support for the latest
        # clang version.
        branch=master
        # We must clone the repo with full depth in this case
        # to include all commits in the history so that we can
        # derive a revision number with `git rev-list`.
        depth_1=
    else
        branch=$(latest_github_repo_tag $acct_name $repo_name)
        depth_1="--depth=1"
    fi
    echo "Cloning branch $branch of $acct_name/$repo_name"
    sleep 3
    git clone $depth --branch=$branch https://github.com/$acct_name/$repo_name
    if (( master )); then
        pushd $repo_name
        version=$(revision_number_for_master)
        popd
    else
        version=$branch
    fi
    echo "Version: $version"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Command line parameters

[[ "$1" =~ --latest-tag ]] && master=0 || master=1

clone_latest_tag $acct $repo $master
cd $repo
mkdir build
cd build

tools="$HOME/dev/tools"
our_tag="iwyu-$version"
prefix="$tools/$our_tag"

echo "Installing to: $prefix"

cmake .. -DCMAKE_PREFIX_PATH="$HOME/dev/tools/llvm-current" \
         -DCMAKE_INSTALL_PREFIX="$prefix"                   \
          ..

if which nproc &>/dev/null; then
    threads=$(nproc --all)
else
    threads=4
fi

make -j$threads
make install

cd $tools
rm -f iwyu-current
ln -s "$our_tag" iwyu-current
