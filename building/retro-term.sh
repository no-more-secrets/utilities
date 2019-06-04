#!/bin/bash
# ---------------------------------------------------------------
# Retro Term
# ---------------------------------------------------------------
# This script will build and install "cool retro term."
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
project_key="cool-retro-term"

cd /tmp

work=$project_key-build
[[ -d $work ]] && /bin/rm -rf "$work"
mkdir -p $work && cd $work

tools="$HOME/dev/tools"
mkdir -p "$tools"

# ---------------------------------------------------------------
# Functions
# ---------------------------------------------------------------
latest_github_repo_tag() {
    local acct="$1"
    local repo="$2"
    local api_url="https://api.github.com/repos/$acct/$repo/tags"
    # FROM: "name": "v8.1.0338",
    # TO:   8.1.0338
    curl --silent $api_url | grep '"name":'                \
                           | sed 's/.*: "v\?\(.*\)".*/\1/' \
                           | grep '^[0-9]'                 \
                           | sort -rV                      \
                           | head -n1
}

clone_latest_tag() {
    local acct="$1"
    local repo="$2"
    # non-local
    version=$(latest_github_repo_tag $acct $repo)
    log "latest version of $acct/$repo: $version"
    sleep 3
    git clone --depth=1         \
              --branch=$version \
              --recursive       \
              https://github.com/$acct/$repo
}

supplemental_install() {
    supp_inst="$this/install-data/$project_key/install"
    #log "Running supplemental install script for $project_key"
    #"$supp_inst"
}

# ---------------------------------------------------------------
# Check version and if it already exists.
# ---------------------------------------------------------------
acct="Swordfish90"
repo="cool-retro-term"

version=$(latest_github_repo_tag $acct $repo)

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
# These are taken from the repo documentation, and may change
# with time. This will be a no-op on OSX.
echo 'You may be asked for your password to install apt dependencies:'
apt_deps="
  build-essential
  qml-module-qtgraphicaleffects
  qml-module-qt-labs-folderlistmodel
  qml-module-qt-labs-settings
  qml-module-qtquick-controls
  qml-module-qtquick-dialogs
  qmlscene
  qt5-default
  qt5-qmake
  qtdeclarative5-dev
  qtdeclarative5-localstorage-plugin
  qtdeclarative5-qtquick2-plugin
  qtdeclarative5-window-plugin
"
echo -e "$apt_deps"

install_apt_dependencies "$apt_deps"

# ---------------------------------------------------------------
# Clone repo
# ---------------------------------------------------------------
clone_latest_tag $acct $repo
cd $repo

# ---------------------------------------------------------------
# Build/Test
# ---------------------------------------------------------------
qmake
make -j"$(build_threads)"

# ---------------------------------------------------------------
# Install
# ---------------------------------------------------------------
# Installation root is specified with the variable below, but the
# installation routine doesn't seem to place all the necessary
# files in the right place, so the program ends up not runnable.
# So instead we'll just copy it ourselves.
# make install INSTALL_ROOT=$prefix

# cool-retro-term puts the executable in the bin folder which
# doesn't work with our standard bin links, so accommodate that
# here.
cd ..
mv $repo $prefix
mkdir $prefix/bin
ln -s $prefix/cool-retro-term $prefix/bin/cool-retro-term

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
