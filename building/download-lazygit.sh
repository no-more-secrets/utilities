#!/bin/bash
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
# Setup.
# ---------------------------------------------------------------
tools=~/dev/tools
mkdir -p "$tools"
cd "$tools"

# ---------------------------------------------------------------
# Github.
# ---------------------------------------------------------------
binary_suffix=Linux_x86_64.tar.gz

latest_release_version() {
  curl -s https://api.github.com/repos/jesseduffield/lazygit/releases \
    | grep -E "$binary_suffix" \
    | sed -rn 's/\s*"browser_download_url": "(.*)"/\1/p' \
    | sed -r 's/.*download.(v[^/]*)\/.*/\1/' \
    | head -n1
}

latest_lazygit_release_url() {
  local version="$1"
  local filename="$2"
  echo "https://github.com/jesseduffield/lazygit/releases/download/$version/$filename"
}

# ---------------------------------------------------------------
# Version.
# ---------------------------------------------------------------
version=$(latest_release_version)
log "latest lazygit release version: $version."
[[ ! -z "$version" ]]

folder_name="lazygit-$version"
[[ -d "$folder_name" ]] && {
  log "release $folder_name already exists, updating links."
  rm -f lazygit-current
  ln -s "$folder_name" lazygit-current
  mkdir -p ~/bin
  rm -f ~/bin/lazygit
  ln -s "$tools/lazygit-current/bin/lazygit" ~/bin/lazygit
  exit 0
}

filename="lazygit_${version//v}_$binary_suffix"
log "filename: $filename"
url="$(latest_lazygit_release_url $version $filename)"
log "latest lazygit release url: $url."
[[ ! -z "$url" ]]

# ---------------------------------------------------------------
# Download.
# ---------------------------------------------------------------
mkdir -p "$folder_name"
pushd "$folder_name"
mkdir -p bin
log "Downloading: $url"
wget "$url"
[[ -e "$filename" ]]
tar xvf "$filename"
[[ -x lazygit ]]
mv lazygit ./bin/
popd

# ---------------------------------------------------------------
# Links.
# ---------------------------------------------------------------
rm -f lazygit-current
ln -s "$folder_name" lazygit-current
mkdir -p ~/bin
rm -f ~/bin/lazygit
ln -s "$tools/lazygit-current/bin/lazygit" ~/bin/lazygit
