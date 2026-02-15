#!/bin/bash
# ===============================================================
# Sync David's Vocal Trance Spotify Playlist.
# ===============================================================
set -eo pipefail

source ~/dev/utilities/bashlib/util.sh

cd_to_this "$0"

sync() {
  local playlist_id="$1"
  local filename="$2"
  local playlist_url="https://open.spotify.com/playlist/$playlist_id"
  echo "syncing $filename..."
  rm -f "$filename.tmp"
  trap "rm -f \"\$filename.tmp\"" EXIT INT TERM
  # -B means don't compile files to avoid creating pyc files.
  python3 -B export-spotify-playlist.py "$playlist_url" > "$filename.tmp"
  mv "$filename.tmp" "$filename"
}

# First decrypt the keys file if it hasn't already been done.
trap "rm keys.py" EXIT INT TERM
[[ ! -f keys.py ]] && {
  gpg --pinentry-mode loopback --output keys.py --decrypt keys.py.asc
}

sync "3YE33l8eAP3zNrtAVDPvsx" davids-vocal-trance.json
# sync "0jHjEJUeGqKisKEagkh46N" colonization-game-soundtrack-originals.json

if git status --porcelain=v1 2>/dev/null | grep json; then
  lazygit
fi

echo "done."
exit 0