import sys, json, spotipy
try:
  import keys
except:
  print( 'ERROR: keys.py.asc must first be decrypted. sync.sh is supposed to do this.', file=sys.stderr )
  exit( 1 )

playlist_url = sys.argv[1]
assert playlist_url

client       = None

print( f'clientId:     {keys.clientId}', file=sys.stderr )
print( f'clientSecret: {keys.clientSecret}', file=sys.stderr )

cred_mgr     = spotipy.oauth2.SpotifyClientCredentials( client_id=keys.clientId, client_secret=keys.clientSecret )
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
