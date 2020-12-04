#!/usr/bin/env python3
import os, sys, re

bonobo = '/sys/devices/LNXSYSTM:00/LNXSYBUS:00/17761776:00/leds/system76_acpi::kbd_backlight/color'
bonobo_color = 'FF1E00' # orange
# bonobo_color = '400540' # dull purple
if os.path.exists( bonobo ):
  kbd_backlight = bonobo
  color         = bonobo_color

darter = '/sys/devices/platform/system76/leds/system76::kbd_backlight/color_left'
darter_color = 'FF5B00'
if os.path.exists( darter ):
  kbd_backlight = darter
  color         = darter_color

if len( sys.argv ) > 1:
  color = sys.argv[1]
  assert re.match( '^[a-fA-F0-9]{6}$', color )
  color = color.upper()

# print( 'setting color: %s' % color )

with open( kbd_backlight, "r+" ) as f:
  f.write( color )
  f.flush()
