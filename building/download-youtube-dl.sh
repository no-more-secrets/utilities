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
key=youtube-dl

tools=~/dev/tools
mkdir -p "$tools"
cd "$tools"

# ---------------------------------------------------------------
# Github.
# ---------------------------------------------------------------
binary_suffix=tar.gz

account=ytdl-org
repo=ytdl-nightly

latest_release_version() {
  curl -s "https://api.github.com/repos/$account/$repo/releases" \
    | grep -E "$binary_suffix" \
    | sed -rn 's/\s*"browser_download_url": "(.*)"/\1/p' \
    | sed -r 's/.*download.([0-9][^/]*)\/.*/\1/' \
    | head -n1
}

latest_release_url() {
  local version="$1"
  local filename="$2"
  echo "https://github.com/$account/$repo/releases/download/$version/$filename"
}

# ---------------------------------------------------------------
# Version.
# ---------------------------------------------------------------
version=$(latest_release_version)
log "latest release version: $version."
[[ ! -z "$version" ]]

folder_name="$key-$version"
[[ -d "$folder_name" ]] && {
  log "release $folder_name already exists, updating links."
  rm -f $key-current
  ln -s "$folder_name" $key-current
  mkdir -p ~/bin
  rm -f ~/bin/$key
  ln -s "$tools/$key-current/bin/$key" ~/bin/$key
  exit 0
}

filename="$key-${version//v}.$binary_suffix"
log "filename: $filename"
url="$(latest_release_url $version $filename)"
log "latest release url: $url."
[[ ! -z "$url" ]]

# ---------------------------------------------------------------
# Download.
# ---------------------------------------------------------------
# This stuff is specific to how youtube-dl is packaged. We need
# to rename the default binary (which is a python script) and
# create a small shell wrapper around it so that we can set the
# right python path. If this is not done then it will either fail
# or (worse) use any youtube-dl python modules that are installed
# in the system, which might be old versions.
log "Downloading: $url"
wget "$url"
[[ -e "$filename" ]]
tar xvf "$filename"
[[ -d "youtube-dl" ]]
[[ -d "youtube-dl/bin" ]]
mv youtube-dl "$folder_name"
[[ -x "$folder_name/bin/youtube-dl" ]]
pushd "$folder_name/bin"
mv youtube-dl youtube-dl-wrapped
cat >> youtube-dl << EOF
#!/bin/bash
set -e
export PYTHONPATH="$tools/$folder_name:$PYTHONPATH"
$tools/$folder_name/bin/youtube-dl-wrapped "\$@"
EOF
chmod u+x youtube-dl
popd
[[ -x "$folder_name/bin/youtube-dl-wrapped" ]]
[[ -x "$folder_name/bin/youtube-dl" ]]
rm "$filename"

# ---------------------------------------------------------------
# Links.
# ---------------------------------------------------------------
rm -f $key-current
ln -s "$folder_name" $key-current
mkdir -p ~/bin
rm -f ~/bin/$key
ln -s "$tools/$key-current/bin/$key" ~/bin/$key
