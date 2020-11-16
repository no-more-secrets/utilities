#!/usr/bin/env python
import time
import sys

if len( sys.argv ) <= 1:
    print( 'Usage: epoch-to-human.py <epoch-time>\n' )
    print( '       where <epoch-time> can be in any units.\n')
    exit( 1 )

t = sys.argv[1]

t_int = long( t )

if len( t ) <= 10:
    # seconds
    seconds = t_int
    microseconds = 0
elif len( t ) <= 13:
    # milliseconds
    seconds = t_int//1000
    microseconds = (t_int % 1000)*1000
elif len( t ) <= 16:
    # microseconds
    seconds = t_int//1000000
    microseconds = t_int % 1000000

local = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(seconds))
utc   = time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime(seconds))

print( "EST: {}.{:06d}".format( local, microseconds ) )
print( "UTC: {}.{:06d}".format( utc,   microseconds ) )