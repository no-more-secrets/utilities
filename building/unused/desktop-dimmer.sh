#!/bin/bash
# ---------------------------------------------------------------
# Desktop Dimmer
# ---------------------------------------------------------------
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
# Create Work Area
# ---------------------------------------------------------------
cd /tmp

project_key="desktop-dimmer"
work=$project_key-build

[[ -d $work ]] && /bin/rm -rf "$work"
mkdir -p $work
cd $work

# ---------------------------------------------------------------
# Functions
# ---------------------------------------------------------------
latest_github_repo_tag() {
  local acct="$1"
  local repo="$2"
  local api_url="https://api.github.com/repos/$acct/$repo/tags"
  # FROM: "name": "v8.1.0338",
  # TO:   v8.1.0338
  curl --silent $api_url | grep '"name":'       \
                         | head -n1             \
                         | sed 's/.*: "\(.*\)".*/\1/'
}

# "desktop-dimmer/now 4.0.4-67 amd64..." --> "4.0.4"
current_installed_version() {
  apt list 2>/dev/null \
      | sed -rn 's/^desktop-dimmer\/[^0-9]+([0-9.]+).*installed.*/\1/p' \
      | sort -V \
      | tail -n1
}

# ---------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------
check_apt_dependencies '
  gdebi
'

# ---------------------------------------------------------------
# Check version and if it already exists.
# ---------------------------------------------------------------
acct="sidneys"
repo="desktop-dimmer"

version=$(latest_github_repo_tag $acct $repo)

installed_version_no_v=$(current_installed_version)
installed_version="v$installed_version_no_v"

[[ "$version" == "$installed_version" ]] && {
    log "version $version is already installed."
    exit 0
}

log "latest version: $version"

# Uninstall if already installed.
[[ ! -z "$installed_version_no_v" ]] && {
  log "uninstalled existing version."
  sudo apt remove -y desktop-dimmer
}

# ---------------------------------------------------------------
# Download Deb Package
# ---------------------------------------------------------------
deb="$repo-${version/v}-amd64.deb"
log "downloading deb package from github."
wget --quiet "https://github.com/$acct/$repo/releases/download/$version/$deb"

# ---------------------------------------------------------------
# Install
# ---------------------------------------------------------------
sudo gdebi $deb --non-interactive

# ---------------------------------------------------------------
# Finish
# ---------------------------------------------------------------
log "success."
