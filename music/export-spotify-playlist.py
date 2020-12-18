import sys, json, spotipy

playlist_url = sys.argv[1]
assert playlist_url

client       = None
clientId     = '4fe3fecfe5334023a1472516cc99d805' # from spotdl
clientSecret = '0f02b7c483c04257984695007a4a8d5c' # from spotdl

cred_mgr     = spotipy.oauth2.SpotifyClientCredentials( client_id=clientId, client_secret=clientSecret )
client       = spotipy.Spotify( client_credentials_manager=cred_mgr )

songs = []
while True:
  playlistResponse = client.playlist_tracks( playlist_url, offset=len(songs) )
  for songEntry in playlistResponse['items']:
    url = 'https://open.spotify.com/track/' + songEntry['track']['id']
    rawTrackMeta = client.track( url )
    songs.append(dict(song_name=rawTrackMeta['name'],
                      album_artists=[artist['name'] for artist in rawTrackMeta['album']['artists']],
                      contrib_artists=[artist['name'] for artist in rawTrackMeta['artists']],
                      album_name=rawTrackMeta['album']['name']))
  # check if more tracks are to be passed        
  if not playlistResponse['next']:
    break

print( json.dumps( songs, indent=2 ) )