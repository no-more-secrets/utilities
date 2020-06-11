#!/bin/bash
# This will open a vim editor and allow the user to enter text.
# The initial contents of the buffer will be populated with the
# contents of stdin if not connected to terminal. If the user
# saves the resulting file (which should be done with `:w<CR>` as
# there is already a filename) then this script will echo that
# content to stdout before exiting.
#
# This script is meant to be used in a pipeline with output piped
# somewhere. For example:
#
#   $ echo hello | vimecho.sh | grep llo
#
# of just:
#
#   $ vimecho.sh | grep llo
#
f="/tmp/vimecho-$(date +%s)"

# If stdin is not terminal then read contents of stdin and put it
# in the file as the initial contents to be edited.
if ! test -t 0; then
  cat >"$f"
fi

log() { echo "$@" 1>&2; }

parent_pid=$(ps -p $$ -o ppid | tail -n 1)
#log "pid:        $$"
#log "parent pid: $parent_pid"

# Get tty from parent because our input/output might be redi-
# rected.
tty=/dev/$(ps -p $parent_pid -o tty | tail -n 1)
#log "tty:        $tty"

# This script is mean to be used in a pipeline, and so normally
# stdout is redirected away from a terminal. In order to make vim
# behave properly under these conditions it is necessary to manu-
# ally connect it back to the terminal.
vim "$f" <$tty >$tty

if [[ -e "$f" ]]; then
  cat "$f"
  ret=0
else
  ret=1
fi

/bin/rm -f "$f"

exit $ret