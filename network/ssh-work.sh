#!/bin/bash
set -eo pipefail

source ~/dev/utilities/bashlib/util.sh

sock=/tmp/ssh-auth.sock

[[ -e $sock ]] || \
  die "auth socket not found; must first run tunnel script on work laptop."

export SSH_AUTH_SOCK=$sock

# Trick used to get bash to source a file before the prompt.
ssh -t localhost -p 43022 '
  # bash command must be on same line as variable setting.
  PROMPT_COMMAND="
    source /tmp/ssh-source.sh
    unset PROMPT_COMMAND
  " exec bash
'