import sys
import json
import spotipy

try:
    import keys
except:
    print(
        "ERROR: keys.py.asc must first be decrypted. sync.sh is supposed to do this.",
        file=sys.stderr,
    )
    sys.exit(1)

playlist = sys.argv[1]
assert playlist

auth_mgr = spotipy.oauth2.SpotifyOAuth(
    client_id=keys.clientId,
    client_secret=keys.clientSecret,
    redirect_uri="http://127.0.0.1:8080/callback",
    scope="playlist-read-private playlist-read-collaborative",
    open_browser=True,
)

client = spotipy.Spotify(auth_manager=auth_mgr)

# Accept either a playlist URL or a playlist ID.
playlist_id = client.playlist(playlist, fields="id")["id"]

songs = []
offset = 0

fields = (
    "items("
        "item("
            "type,"
            "name,"
            "artists(name),"
            "album("
                "name,"
                "artists(name)"
            ")"
        ")"
    "),"
    "next,"
    "limit"
)

while True:
    playlist_response = client._get(
        f"playlists/{playlist_id}/items",
        limit=100,
        offset=offset,
        fields=fields,
        additional_types="track",
    )

    for song_entry in playlist_response["items"]:
        track = song_entry.get("item")

        if not track or track.get("type") != "track":
            continue

        songs.append(
            {
                "song_name": track["name"],
                "album_artists": [
                    artist["name"]
                    for artist in track["album"]["artists"]
                ],
                "contrib_artists": [
                    artist["name"]
                    for artist in track["artists"]
                ],
                "album_name": track["album"]["name"],
            }
        )

    if not playlist_response["next"]:
        break

    offset += playlist_response["limit"]

print(json.dumps(songs, indent=2))
