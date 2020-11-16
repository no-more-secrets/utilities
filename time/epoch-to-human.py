#!/usr/bin/env python
import time
import sys

if len( sys.argv ) <= 1:
    print( 'Usage: epoch-to-human.py <epoch-time>\n' )
    print( '       where <epoch-time> can be in any units.\n')
    exit( 1 )

t = sys.argv[1]

t_int = int( t )

if t_int <= 9999999999:
    # seconds
    seconds = t_int
    microseconds = 0
elif t_int <= 9999999999999:
    # milliseconds
    seconds = t_int//1000
    microseconds = (t_int % 1000)*1000
elif t_int <= 9999999999999999:
    # microseconds
    seconds = t_int//1000000
    microseconds = t_int % 1000000

local = time.strftime('%Y-%m-%d %H:%M:%S.%06d', time.localtime(seconds))
utc   = time.strftime('%Y-%m-%d %H:%M:%S.%06d', time.gmtime(seconds))

print( "EST: {}.{:06d}".format( local, microseconds ) )
print( "UTC: {}.{:06d}".format( utc,   microseconds ) )