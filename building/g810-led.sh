#!/bin/bash
# ---------------------------------------------------------------
# g810-led
# ---------------------------------------------------------------
# This builds a tool that can set the keyboard backlight colors
# on logitech keyboards.  Despite the "810" in the name, it can
# support multiple model numbers, including e.g. the G915.
#
# FIXME: currently this script is building a fork/branch for a PR
# that adds support for the G915. When that is merged then we
# should switch to the main repo and master branch. Eventually,
# when that change makes its way into the Ubuntu package repo (an
# older version of the tool is indeed in the apt repo) then we
# can probably retire this script altogether. However, note that
# currently there are two build modes of this library, one with
# libusb and another with "hidapi", and we are building with
# libusb because in the PR it mentions that the G915 only works
# in that mode. So for that reason we may need to continue
# building this tool even after the one in the package repo sup-
# ports the keyboards that we want. Time will tell.
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
project_key="g810-led"

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
clone_repo() {
    local acct="$1"
    local repo="$2"
    [[ -z "$version" ]] && die "no version to clone"
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
# FIXME: special fork/branch that supports the G915-led.  After
# this PR gets merged:
#
#   https://github.com/MatMoul/g810-led/pull/267
#
# then we should be able to switch to the main repo and main
# branch, which would be:
#
#   acct="MatMoul"
#   version=master
#
# but for now we need to use the branch from the PR:
acct="yawor"
repo="g810-led"
version=g915_new

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
  libusb-1.0-0-dev
"
echo -e "$apt_deps"

install_if_not_installed "$apt_deps"

# ---------------------------------------------------------------
# Clone Repo
# ---------------------------------------------------------------
clone_repo "$acct" "$repo"
cd $repo

# ---------------------------------------------------------------
# Build
# ---------------------------------------------------------------
make LIB=libusb -j$(build_threads)

# ---------------------------------------------------------------
# Install
# ---------------------------------------------------------------
target_dir="$tools/$project_key-$version"
rm -rf "$target_dir"
mkdir -p "$target_dir"
cp -r ./ "$target_dir/"

# ---------------------------------------------------------------
# Make Links
# ---------------------------------------------------------------
tools_link $project_key
bin_links $project_key

# ---------------------------------------------------------------
# Finish
# ---------------------------------------------------------------
log "success."
