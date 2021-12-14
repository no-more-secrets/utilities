#!/bin/bash

# This is a special build of the fork/branch:
#
#   https://github.com/yawor/g810-led.git : branch g915_new
#
# from PR:
#
#   https://github.com/MatMoul/g810-led/pull/267
#
# which is a PR to add support for the G915. It should be merged
# soon, in which case we can build master. Then, eventually, the
# g810-led that is in the Ubuntu package base should be updated
# to include support for that.
#
# That said, at the time of writing, the tool can be built in two
# modes, one with libusb, and another with "hidapi", but appar-
# ently the G915 feature only currently works with libusb, and so
# we have built the tool in that mode (not sure if the package
# manager version will be built with that mode and/or if it will
# be fixed to support G915 in that mode; if not, then we might
# have to continue building this tool ourselves).
#
# Note that the commands used were taken from:
#
#   https://womanonrails.com/logitech-g915-tkl
#
# although one should be able to deduce them by running the com-
# mand with --help.
#
tool=~/dev/tools/g810-led-current/bin/g810-led

g915_led() {
  # Specify device and product ID to refer to Logitech G915 TKL.
  # -tuk 5 means "test unsupported keyboard", and I'm guessing we
  # can remove that once the tool gets the G915 feature merged
  # properly.
  sudo $tool -dv 046d -dp c545 -tuk 5 "$@"
}

# The tool is supposed to be able to control all keys on the key-
# board by default, but when we try to do that, it somehow leaves
# out certain keys, and so we need to set them group by group as
# a workaround.  That also gives us more flexibility anyway.
off_groups='
  logo
'

on_groups='
  indicators
  multimedia
  fkeys
  modifiers
  arrows
  numeric
  functions
  keys
  gkeys
'

color=ff5b00 # orange

for g in $on_groups; do
  g915_led -g $g $color
done

for g in $off_groups; do
  g915_led -g $g -1 # apparently -1 means "off".
done