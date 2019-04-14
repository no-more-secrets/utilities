#!/bin/bash
# ---------------------------------------------------------------
# Haskell Stack
# ---------------------------------------------------------------
set -e
set -o pipefail

# Must be done first.
this=$(cd $(dirname $0) && pwd)
cd $this

# ---------------------------------------------------------------
# Includes
# ---------------------------------------------------------------
source util.sh

die "unfinished"

# Implementation steps:
#   1) download the install script with
#         curl -sSL https://get.haskellstack.org/ | sh
#   2) Grep that script for the STACK_VERSION variable to get version
#   3) If not already installed, install it ~/dev/tools/stack-$STACK_VERSION
#   4) Rename the binary from stack-$STACK_VERSION to stack
#   6) Create link ~/dev/tools/stack-current to the folder
#   5) Create link in ~/bin to ~/dev/tools/stack-current/stack
