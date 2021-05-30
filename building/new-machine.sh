#!/bin/bash
# ---------------------------------------------------------------
# Build all the things
# ---------------------------------------------------------------
set -eE
set -o pipefail

# Must be done first.
this=$(cd $(dirname $0) && pwd)
cd $this

tools=~/dev/tools
mkdir -p "$tools"

# ---------------------------------------------------------------
# Includes
# ---------------------------------------------------------------
source util.sh

[[ ! -d "$tools/ninja" ]] && \
  bash ninja.sh

bash lazygit.sh

bash gcc.sh

bash clang-rn-pgo.sh

bash lua-format.sh

bash aseprite.sh

bash rosegarden.sh