#!/bin/bash
# This script actually downloads bazelisk (not bazel directly),
# which is a small bazel wrapper tool that is invoked wherever
# bazel would be invoked, but automatically downloads the needed
# version of bazel.
set -e
set -o pipefail

# ---------------------------------------------------------------
# Setup.
# ---------------------------------------------------------------
tools=~/dev/tools
mkdir -p "$tools"
cd "$tools"

binary_name=bazelisk-linux-amd64
rm -f bazelisk-linux-amd64
rm -f bazelisk-linux-amd64.?

# ---------------------------------------------------------------
# Github.
# ---------------------------------------------------------------
latest_bazelisk_release_version() {
  curl -s https://api.github.com/repos/bazelbuild/bazelisk/releases \
    | grep -E "$binary_name" \
    | sed -rn 's/\s*"browser_download_url": "(.*)"/\1/p' \
    | sed -r 's/.*download.(v[^/]*)\/.*/\1/' \
    | head -n1
}

latest_bazelisk_release_url() {
  local version="$1"
  echo "https://github.com/bazelbuild/bazelisk/releases/download/$version/$binary_name"
}

# ---------------------------------------------------------------
# Version.
# ---------------------------------------------------------------
version=$(latest_bazelisk_release_version)
echo "latest bazelisk release version: $version."
[[ ! -z "$version" ]]

folder_name="bazelisk-$version"
[[ -d "$folder_name" ]] && {
  echo "release $folder_name already exists, updating links."
  rm -f bazelisk-downloaded bazelisk-current
  ln -s "$folder_name" bazelisk-downloaded
  ln -s "$folder_name" bazelisk-current
  mkdir -p ~/bin
  rm -f ~/bin/bazel
  ln -s "$tools/bazelisk-current/$binary_name" ~/bin/bazel
  exit 0
}

url="$(latest_bazelisk_release_url $version)"
echo "latest bazelisk release url: $url."
[[ ! -z "$url" ]]

# ---------------------------------------------------------------
# Download.
# ---------------------------------------------------------------
echo "Downloading: $url"
wget "$url"
[[ -e "$binary_name" ]]
chmod u+x "$binary_name"
mkdir -p "$folder_name"
mv "$binary_name" "$folder_name"
binary_path="$tools/$folder_name/$binary_name"

# ---------------------------------------------------------------
# Links.
# ---------------------------------------------------------------
rm -f bazelisk-downloaded bazelisk-current
ln -s "$folder_name" bazelisk-downloaded
ln -s "$folder_name" bazelisk-current

# Henceforth, when we run bazel, we actually run bazelisk. This
# will auto-install bazel for us if it hasn't been installed and
# will also check for a .bazelversion for project-specific bazel
# versions and will use the right one.
mkdir -p ~/bin
rm -f ~/bin/bazel
ln -s "$tools/bazelisk-current/$binary_name" ~/bin/bazel
