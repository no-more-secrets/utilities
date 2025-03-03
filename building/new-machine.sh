#!/bin/bash
# ---------------------------------------------------------------
# Build all the things
# ---------------------------------------------------------------
set -eE
set -o pipefail

# ---------------------------------------------------------------
# Includes
# ---------------------------------------------------------------
source ~/dev/utilities/bashlib/util.sh
source ~/dev/utilities/building/util.sh

# ---------------------------------------------------------------
# Setup
# ---------------------------------------------------------------
cd_to_this "$0"

tools=~/dev/tools
mkdir -p "$tools"

# ---------------------------------------------------------------
# Build
# ---------------------------------------------------------------
log '=========================== ninja ==========================='
bash ninja.sh

log '========================= youtube-dl ========================'
bash download-youtube-dl.sh

log '=========================== nvim ============================'
bash nvim.sh

log '========================== lazygit =========================='
bash download-lazygit.sh

log '======================== lua-format ========================='
bash lua-format.sh

log '==================== lua-language-server ===================='
bash lua-language-server.sh

log '=================== glsl-language-server ===================='
bash glsl-language-server.sh

log '========================= aseprite =========================='
bash aseprite.sh

log '============================ gcc ============================'
bash gcc.sh # must come before clang-rn-pgo.

log '========================== clang ============================'
bash clang-rn-pgo.sh

log '========================= finished =========================='