#!/bin/bash
set -eo pipefail

source ~/dev/utilities/bashlib/util.sh

sock=/tmp/ssh-auth.sock

[[ -e $sock ]] || \
  die "auth socket not found; must first run tunnel script on work laptop."

export SSH_AUTH_SOCK=$sock

ssh -t localhost -p 43022 '
  source /tmp/ssh-source.sh
  fish
'