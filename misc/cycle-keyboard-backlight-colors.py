#!/usr/bin/env python3
import colorsys
import time
import os

bonobo = '/sys/devices/LNXSYSTM:00/LNXSYBUS:00/17761776:00/leds/system76_acpi::kbd_backlight/color'
if os.path.exists( bonobo ):
  kbd_backlight = bonobo

darter = '/sys/devices/platform/system76/leds/system76::kbd_backlight/color_left'
if os.path.exists( darter ):
  kbd_backlight = darter

def drawRainbow():
  with open( kbd_backlight, "r+" ) as f:
    for i in range( 1000 ):
      r, g, b = colorsys.hsv_to_rgb(i/100, 1.0, 1.0)
      hexcolor = '%02x%02x%02x' % ( int(r*255), int(g*255), int(b*255) )
      print( '> hexcolor: ' + hexcolor )
      f.write( hexcolor )
      f.flush()
      time.sleep( 2 )

while True:
  drawRainbow()
