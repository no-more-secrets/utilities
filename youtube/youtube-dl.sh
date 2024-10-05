#!/bin/bash
set -eo pipefail

# E.g.: https://www.youtube.com/watch?v=lcbIhuluu1Q
url=$1

# E.g.: "squirrel-mike-telephone-lady-gaga"
stem=$2

usage() {
  echo "usage: $0 <url> <output-stem>"
  exit 1
}

[[ -n "$url"  ]] || usage
[[ -n "$stem" ]] || usage

# We need to use the one that we download (via the
# download-youtube-dl.sh build script) because at the time of
# writing the one in the distro package is too old of a version
# and fails.
youtube_dl=~/dev/tools/youtube-dl-current/bin/youtube-dl

# This uses youtube-dl's template feature to allow us to specify
# the output file name without having to know the extension/file-
# type that youtube-dl will choose.
$youtube_dl -f best "$url" -o "$stem.%(ext)s"
