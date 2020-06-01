#!/bin/bash
# SFPACK is a utility for unpacking *.sfpack files which
# typically contain *.sf2 files (sound-font files used
# for playing midi music).

cd $(dirname $0)

which wine >/dev/null || {
  echo 'Must install `wine`.'
  exit 1
}

wine SFPACK.EXE
