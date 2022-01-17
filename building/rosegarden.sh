#!/bin/bash
# ---------------------------------------------------------------
# Rosegarden
# ---------------------------------------------------------------
# This script will build the latest tag of Rosegarden.
set -e
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
project_key="rosegarden"

cd /tmp

work=$project_key-build
[[ -d $work ]] && /bin/rm -rf "$work"
mkdir -p $work && cd $work

tools="$HOME/dev/tools"
mkdir -p "$tools"

# ---------------------------------------------------------------
# Functions
# ---------------------------------------------------------------
latest_svn_repo_tag() {
    local repo="$1"
    # "rosegarden-19.06/" --> "19.06"
    svn ls "$repo" | grep rosegarden-                  \
                   | sort -V                           \
                   | sed -r 's/rosegarden-(.*)\//\1/g' \
                   | tail -n1
}

checkout_latest_tag() {
    local repo="$1"
    local tag="$2"
    svn co $repo/$tag
}

supplemental_install() {
    supp_inst="$this/install-data/$project_key/install"
    log "Running supplemental install script for $project_key"
    "$supp_inst"
}

# ---------------------------------------------------------------
# Check version and if it already exists.
# ---------------------------------------------------------------
repo_tags="http://svn.code.sf.net/p/rosegarden/code/tags"

version=$(latest_svn_repo_tag $repo_tags)
echo "latest version: $version"

[[ -e "$tools/$project_key-$version" ]] && {
    log "$project_key-$version already exists, activating it."
    tools_link $project_key
    bin_links $project_key
    supplemental_install
    exit 0
}

prefix="$tools/$project_key-$version"

# ---------------------------------------------------------------
# Check apt Dependencies
# ---------------------------------------------------------------
# This will install apt packages that are required for the build.
# These were determined empirically, and may change with time
# and/or with Linux distribution. This will be a no-op on OSX.
echo 'You may be asked for your password to install apt dependencies:'
apt_deps="
    dssi-dev
    ladspa-sdk-dev
    libfftw3-dev
    libjack-dev
    liblo-dev
    liblrdf-dev
    libsamplerate-dev
    libsndfile-dev
    qttools5-dev
    qttools5-dev-tools
"
echo -e "$apt_deps"

install_if_not_installed "$apt_deps"

# ---------------------------------------------------------------
# Checkout repo
# ---------------------------------------------------------------
checkout_latest_tag $repo_tags rosegarden-$version
cd rosegarden-$version

# ---------------------------------------------------------------
# Configure
# ---------------------------------------------------------------
mkdir build
cd build
run_cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo \
             -DCMAKE_INSTALL_PREFIX=$prefix

# ---------------------------------------------------------------
# Build
# ---------------------------------------------------------------
ninja

# ---------------------------------------------------------------
# Install
# ---------------------------------------------------------------
ninja install

# ---------------------------------------------------------------
# Supplemental Installation Steps
# ---------------------------------------------------------------
supplemental_install

# ---------------------------------------------------------------
# Make symlinks
# ---------------------------------------------------------------
tools_link $project_key
bin_links  $project_key

log "Success."
