#!/bin/bash
# ---------------------------------------------------------------
# Aseprite: Pixel Art Editor
# ---------------------------------------------------------------
# This script will first run the skia-aseprite.sh script to build
# the latest version of skia (which is an aseprite dependency in
# later versions). It will then build the latest tag of aseprite.
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
project_key="aseprite"

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
    # TO:   v8.1.0338
    # There's a strange tag called v7_0_2beta that is very old
    # that we don't want (it would otherwise come up because it
    # has the most recent version number by far).
    curl --silent $api_url | grep '"name":'       \
                           | grep -v 'v7_0_2beta' \
                           | head -n1             \
                           | sed 's/.*: "\(.*\)".*/\1/'
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
    log "Running supplemental install script for $project_key"
    "$supp_inst"
}

# ---------------------------------------------------------------
# Check version and if it already exists.
# ---------------------------------------------------------------
acct="aseprite"
repo="aseprite"

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
# This will check for the presence of (but not install) apt pack-
# ages that are required for the build. These are taken from the
# Aseprite INSTALL.md file, and may change with time. This will
# be a no-op on OSX.
check_apt_dependencies "
  libx11-dev
  libxcursor-dev
  libgl1-mesa-dev
  libfontconfig1-dev
"

# ---------------------------------------------------------------
# Clone repo
# ---------------------------------------------------------------
clone_latest_tag $acct $repo
cd $repo

# ---------------------------------------------------------------
# Build `skia` if necessary.
# ---------------------------------------------------------------
get_skia_version() {
  local ver=$(cat INSTALL.md                    \
      | sed -rn 's/.*(aseprite-m[0-9]+).*/\1/p' \
      | sort -ru)
  echo "$ver"
}

log "getting skia version..."
skia_version="$(get_skia_version)"
log "found skia version: $skia_version."
[[ "$skia_version" =~ ^aseprite-m[0-9]+$ ]] || \
    die "failed to find skia version."

$this/skia-aseprite.sh "$skia_version"

skia_current="$tools/skia-current"
[[ -e "$skia_current" ]] || \
    die "Skia not found (the above script should have built it)."

skia_real_version=$(real_path $skia_current)
log "skia_real_version: $skia_real_version"
skia_lib_dir="$skia_real_version/out/Release"
log "skia_lib_dir: $skia_lib_dir"

# ---------------------------------------------------------------
# Run CMake
# ---------------------------------------------------------------
# Need to ensure that the system ninja is installed in at the
# front of the path so that CMake does not try to use our custom
# ninja which causes issues when it is testing compilation.
export PATH="/usr/bin:$PATH"
[[ "$(which ninja)" == "/usr/bin/ninja" ]] || \
  die "need to install ninja on the system."

cd /tmp/$work/$repo && mkdir -p build && cd build
# Use the deferenced path for the skia directory because we are
# building against it and so we don't want a given version of
# aseprite to break if the skia-current symlink changes.
cmake .. -DSKIA_DIR=$skia_real_version                 \
         -DSKIA_LIBRARY_DIR=$skia_lib_dir              \
         -DCMAKE_INSTALL_PREFIX="$prefix"              \
         -DLAF_BACKEND=skia                            \
         -DCMAKE_BUILD_TYPE=RelWithDebInfo             \
         -DSKIA_OUT_DIR=$skia_real_version/out/Release \
         -DLAF_WITH_EXAMPLES=OFF                       \
         -DLAF_WITH_TESTS=OFF                          \
         -G Ninja

# ---------------------------------------------------------------
# Build/Test
# ---------------------------------------------------------------
ninja && ninja install

# Apparently needed on OSX (though still needs to be run from the
# bin folder. This may be fixed in a future version.
cd "$prefix"/bin
ln -s ../share/aseprite/data data

$prefix/bin/aseprite --version

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

post_install_message "
  If on Linux then Aseprite's default Alt-Click shortcut for
  the eyedropper tool will not work because of the window
  managers behavior of capturing Alt-Click to move a window.
  To disable this behavior in the window manager follow these
  steps:

    1) Install and open Dconf-Editor
    2) Go to: org > cinnamon > desktop > wm > preferences
    3) Change the mouse-button-modifier to <Super> (not blank!)
"
