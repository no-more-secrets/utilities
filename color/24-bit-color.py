#!/usr/bin/env python
import sys, os

def set_background_color( r, g, b ):
  #  print( 'r=%s\ng=%s\nb=%s\n' % (r, g, b) )
  sys.stdout.write( '\x1b[48;2;%s;%s;%sm' % (int(r), int(g), int(b)) )

def reset_output():
  sys.stdout.write( "\x1b[0m" )

def print_rgb_colored_space( r, g, b ):
  set_background_color( r, g, b )
  sys.stdout.write( ' ' )

def hsl_to_rgb( h, s, l ):
  # www.rapidtables.com/convert/color/hsl-to-rgb.html
  C = ( 1 - abs( 2.0 * l - 1.0 ) ) * s;
  X = C * ( 1.0 - abs( ( ( h / 60.0 ) % 2.0 ) - 1.0 ) );
  m = l - C / 2.0;
  R = 0
  G = 0
  B = 0

  if 0   <= h and h <  60:
    R = C
    G = X
    B = 0
  if 60  <= h and h < 120:
    R = X
    G = C
    B = 0
  if 120 <= h and h < 180:
    R = 0
    G = C
    B = X
  if 180 <= h and h < 240:
    R = 0
    G = X
    B = C
  if 240 <= h and h < 300:
    R = X
    G = 0
    B = C
  if 300 <= h and h < 360:
    R = C
    G = 0
    B = X

  r = ( R + m ) * 255.0;
  g = ( G + m ) * 255.0;
  b = ( B + m ) * 255.0;
  return r, g, b

def print_hsl_colored_space( h, s, l ):
  #  print( 'r=%s\ng=%s\nb=%s\n' % hsl_to_rgb( h, s, l ) )
  #  print( 'h=%s\ns=%s\nl=%s\n' % (h, s, l) )
  print_rgb_colored_space( *hsl_to_rgb( h, s, l ) )

#  cols = int( os.environ['COLUMNS'] )
#  rows = 40
rows, cols = os.popen( 'stty size', 'r' ).read().split()
rows, cols = int( rows ), int( cols )

rows = rows - 1

lit = 0.5 # .5 is "normal"

for sat in range( 0, rows ):
  for hue in range( 0, cols ):
    print_hsl_colored_space( 360.0*hue/float(cols), 1.0-sat/float(rows), lit )
  sys.stdout.write( '\n' )

reset_output()
