import sys, json, spotipy

playlist_url = sys.argv[1]
assert playlist_url

client       = None
clientId     = "fdf2063fa3454cc6a614cca3f6777720" # from my spotify account
clientSecret = "92b032e66cd7467391490867cb12a91e" # from my spotify account

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
