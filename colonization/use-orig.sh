#!/bin/bash
set -e
set -x
# This will enable the non-patched version that has the buggy RNG
# generator fixed. That process is first fix described here:
#
#   https://civilization.fandom.com/wiki/Bugs_(Col)
#
# Note that, as described there, this version is needed in order
# to get random map generations. So when starting a new map one
# should use-orig.sh, then when playing or experimenting one
# should use-fixed.sh. This is likely because the original code
# will re-seed the RNG with the current time each time it is
# called (leading to non-random "streaks"), whereas the patched
# version prevents it from doing that, leading to more random be-
# havior but without ever randomly seeding it at the start of the
# program.
cp data/MPS/COLONIZE/VICEORIG.EXE data/MPS/COLONIZE/VICEROY.EXE
