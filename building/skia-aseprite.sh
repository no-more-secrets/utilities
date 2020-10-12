#!/bin/bash
# ---------------------------------------------------------------
# Skia: cross-platform basic 2D graphics library
# ---------------------------------------------------------------
# This script will build the version of `skia` used as a depen-
# dency by Aseprite and install it to the tools folder. It is a
# bit large -- 2GB -- on account of the third_party folder that
# it contains (which we cannot remove because it is required to
# build Aseprite). So therefore old versions should be removed.
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
# Get Version
# ---------------------------------------------------------------
target_branch="$1"
[[ -z "$target_branch" ]] && die "first arg must be target branch."
log "target version: $target_branch."

# ---------------------------------------------------------------
# Initialization
# ---------------------------------------------------------------
# This must be a lowercase short word with no spaces describing
# the software being built. Folders/links will be named with
# this.
project_key="skia"

cd /tmp

work=$project_key-build
[[ -d $work ]] && /bin/rm -rf "$work"
mkdir -p $work && cd $work

tools="$HOME/dev/tools"
mkdir -p "$tools"

# ---------------------------------------------------------------
# Functions
# ---------------------------------------------------------------
clone_latest_branch() {
    local acct="$1"
    local repo="$2"
    local version="$3"
    git clone --depth=1         \
              --branch=$version \
              --recursive       \
              https://github.com/$acct/$repo
}

# ---------------------------------------------------------------
# Check version
# ---------------------------------------------------------------
acct="aseprite"
repo="skia"

version="$target_branch"

[[ -e "$tools/$project_key-$version" ]] && {
    log "$project_key-$version already exists, activating it."
    tools_link $project_key
    exit 0
}

# ---------------------------------------------------------------
# Clone depo_tools
# ---------------------------------------------------------------
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

# This is needed for the `gn` tool below.
export PATH="$PWD/depot_tools:$PATH"

# ---------------------------------------------------------------
# Clone aseprite-skia repo and dependencies
# ---------------------------------------------------------------
clone_latest_branch $acct $repo "$target_branch"

cd skia

# If you get a weird transient git error while cloning a repo,
# e.g.:
#
#   inflate data stream error invalid "distance too far back"
#
# Then do the following:
#
#   1. Open the /tmp/skia-build/skia/tools/git-sync-deps file and
#      find the lines that do the git clone and git checkout and
#      remove the --quiet and --no-checkout from them, e.g.:
#
#        subprocess.check_call([git, 'clone', repo, directory])
#        subprocess.check_call([git, 'checkout', commithash], cwd=directory)
#
#   2. Copy the resulting file to /tmp.
#   3. Uncomment the `cp` command below.
#
# The suspicion is that the build system is doing too many git
# clones in parallel and runs into transient errors. By removing
# the --checkout flag it may perturb the process (slowing it down
# a bit) so that it doesn't fail.
#
# If this doesn't work then maybe need to look into changing the
# skia build script so that it does not parallelize the cloning
# of the git repos.
#
#cp /tmp/git-sync-deps tools/git-sync-deps # UNCOMMENT
python tools/git-sync-deps

# ---------------------------------------------------------------
# Configure
# ---------------------------------------------------------------
gn gen out/Release --args="
    is_debug=false
    is_official_build=true
    skia_use_system_expat=false
    skia_use_system_icu=false
    skia_use_system_libjpeg_turbo=false
    skia_use_system_libpng=false
    skia_use_system_libwebp=false
    skia_use_system_zlib=false
"

# ---------------------------------------------------------------
# Build
# ---------------------------------------------------------------
ninja -C out/Release all

# ---------------------------------------------------------------
# Install/Copy
# ---------------------------------------------------------------
cd ..

prefix="$tools/$project_key-$version"

# The `gn` tools doesn't seem to have an install feature, so we
# just install by copying it.
mv skia $prefix

# ---------------------------------------------------------------
# Create Symlinks
# ---------------------------------------------------------------
tools_link $project_key
