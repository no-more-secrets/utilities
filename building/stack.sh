#!/bin/bash
# ---------------------------------------------------------------
# Haskell Stack
# ---------------------------------------------------------------
set -e
set -o pipefail

# Must be done first.
this=$(cd $(dirname $0) && pwd)
cd $this

tools="$HOME/dev/tools"
mkdir -p "$tools"

# ---------------------------------------------------------------
# Includes
# ---------------------------------------------------------------
source util.sh

project_key=stack

script_dl="curl -sSL https://get.haskellstack.org/"

# ---------------------------------------------------------------
# Check version and if it already exists.
# ---------------------------------------------------------------
echo 'Go to https://docs.haskellstack.org/en/stable/ChangeLog/'
echo 'and look at the latest stack version and enter it here'
echo 'without the leading v:'
read -p '> ' version

log "latest version: $version"

[[ "$version" =~ ^[0-9.]+$ ]] || die "unexpected version format."

[[ -e "$tools/$project_key-$version" ]] && {
    log "$project_key-$version already exists, activating it."
    tools_link $project_key
    bin_links $project_key
    #supplemental_install
    exit 0
}


# ---------------------------------------------------------------
# Download / Install
# ---------------------------------------------------------------
dest="$HOME/dev/tools/stack-$version"

$script_dl | sh -s - -d $dest

mkdir "$dest/bin"
ln -s "$dest/stack" "$dest/bin/stack"

# ---------------------------------------------------------------
# Make symlinks
# ---------------------------------------------------------------
tools_link $project_key
bin_links  $project_key

# ---------------------------------------------------------------
# Test Version
# ---------------------------------------------------------------
# Get the version of stack and make sure that it lines up exactly
# with what the user entered.
actual_version=$(stack --version \
                   | sed -rn 's/^Version ([0-9.]+),.*/\1/p')
[[ "$actual_version" == "$version" ]] || \
    die "Actual version of Stack ($actual_version) does not " \
        "match with version entered ($version)."

log "Success."
