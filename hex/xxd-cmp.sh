#!/bin/bash
set -eo pipefail

f0=~/games/colonization/data/MPS/COLONIZE/COLONY04.SAV
f1=~/games/colonization/data/MPS/COLONIZE/COLONY05.SAV

xxd -c32 $f0 | cut -f-18 -d' ' > /tmp/xxd-cmp-0.hex
xxd -c32 $f1 | cut -f-18 -d' ' > /tmp/xxd-cmp-1.hex

diff -u /tmp/xxd-cmp-0.hex /tmp/xxd-cmp-1.hex