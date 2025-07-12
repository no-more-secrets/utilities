#!/bin/bash
set -e

# This will scan the local network, pop up an fzf menu to let the
# user choose a host, then will emit its IP.

cd ~/dev/utilities/network

./scan-local-network --json     \
  | jq -c -r -f fzf-networks.jq \
  | column -t                   \
  | fzf                         \
  | awk '{ print $1 }'