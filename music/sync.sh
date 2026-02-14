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
  python3 export-spotify-playlist.py "$playlist_url" > $filename
}

sync "3YE33l8eAP3zNrtAVDPvsx" davids-vocal-trance.json
# sync "0jHjEJUeGqKisKEagkh46N" colonization-game-soundtrack-originals.json

if git status --porcelain=v1 2>/dev/null | grep json; then
  lazygit
fi

echo "done."
exit 0