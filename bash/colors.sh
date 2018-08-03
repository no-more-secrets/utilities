#!/bin/bash
# Here's a script to list the colors in the 256-color palette
# along with their ANSI color code in XTerm/ANSI-compatible
# terminals with a 256-color palette support.
for ((i=16; i<256; i++)); do
    printf "\e[48;5;${i}m%03d" $i;
    printf '\e[0m';
    [ ! $((($i - 15) % 6)) -eq 0 ] && printf ' ' || printf '\n'
done
