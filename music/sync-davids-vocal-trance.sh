#!/bin/bash
# ===============================================================
# Sync David's Vocal Trance Spotify Playlist.
# ===============================================================
set -e
set -o pipefail

this="$(dirname "$(readlink -f "$0")")"
cd "$this"

# David's Vocal Trance
playlist_id="3YE33l8eAP3zNrtAVDPvsx"

playlist_url="https://open.spotify.com/playlist/$playlist_id"

python3 export-spotify-playlist.py "$playlist_url" > ./davids-vocal-trance.json

if git status --porcelain=v1 2>/dev/null | grep vocal-trance; then
  lazygit
fi

exit 0