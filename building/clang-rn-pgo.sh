#!/bin/bash
# ---------------------------------------------------------------
#                        Clang PGO Build
# ---------------------------------------------------------------
# NOTE: there are four stages in this build, and each one has a
#       marker file/link that it checks for to see if the stage
#       has already been done.  If you want to force all or some
#       stages to rerun, make sure to locate the marker files and
#       make sure that they are deleted.
set -e
set -o pipefail

# ---------------------------------------------------------------
# Imports
# ---------------------------------------------------------------
source ~/dev/utilities/bashlib/util.sh

cd_to_this "$0"

# ---------------------------------------------------------------
# Constants
# ---------------------------------------------------------------
tools=$HOME/dev/tools
profdata=/tmp/rn-profdata.prof

# ---------------------------------------------------------------
# CLI arguments
# ---------------------------------------------------------------
usage() {
  error "usage: $0 <tag>"
  error ""
  error "  tag: e.g. llvmorg-19.1.0"
  exit 1
}

tag="$1"
[[ -z "$tag" ]] && usage

# ---------------------------------------------------------------
# Recovery
# ---------------------------------------------------------------
# If we got interrupted, restore llvm-current to the stage 1.
pushd "$tools"
if [[ -e llvm-current-bak ]]; then
  rm -f llvm-current
  mv llvm-current-bak llvm-current
fi
popd

# ---------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------
make_retry() {
  local target="$1"
  local cmd
  [[ ! -z "$target" ]] && cmd="make $target KEEP_GOING=" \
                       || cmd="make KEEP_GOING="
  while true; do
    $cmd && break
    echo 'FAILED... RETRYING...'
    sleep 60
  done
}

# ---------------------------------------------------------------
#                            Stage 1
# ---------------------------------------------------------------
# Stage 1, download if necessary (only for new machines).
if [[ ! -e "$tools/llvm-current" ]]; then
  bash download-llvm.sh
  [[ -e "$tools/llvm-current" ]]
else
  echo "Skipping stage 1 as it already exists."
fi

# Record which folder it is so that we can restore it.
pushd "$tools"
rm -f llvm-current-bak
cp -P llvm-current llvm-current-bak
popd

# ---------------------------------------------------------------
#                            Stage 2
# ---------------------------------------------------------------
# Stage 2. Build clang with instrumentation, using clang.
if [[ ! -e "$tools/llvm-inst-current" ]]; then
  ./clang.sh --use-clang=$HOME/dev/tools/llvm-current \
             --skip-confirmation                      \
             --skip-tests                             \
             --use-commit="$tag"                      \
             --clang-opts                             \
             --with-inst
  pushd $HOME/dev/tools
  new_llvm="$(basename $(readlink -f llvm-current))"
  ln -s $new_llvm llvm-inst-current
  popd
else
  echo "Skipping stage 2 as it is already built."
fi

# Make the instrumented build the current one.
pushd "$tools"
rm -f llvm-current
cp -P llvm-inst-current llvm-current
popd

# ---------------------------------------------------------------
#                        Build Profile Data
# ---------------------------------------------------------------
# Use this clang to build revolution-now.
if [[ ! -e "$profdata" && ! -e "$tools/llvm-pgo-current" ]]; then
  profiles=/tmp/compile-profiles
  mkdir -p "$profiles"
  # %p and %m try to ensure that each invocation of the compiler
  # writes to a separate file to avoid clobbery.
  export LLVM_PROFILE_FILE="$profiles/rn-%p-%m.profraw"
  # Clear existing profiling data.
  /bin/rm -f $profiles/*.profraw
  rm -rf /tmp/revolution-now
  git clone ssh://git@github.com/revolution-now/revolution-now \
            /tmp/revolution-now --recursive
  pushd /tmp/revolution-now
  # Note at this point llvm-current points to the instrumented
  # build.
  cmc --clang --lld --libstdcxx --release
  ccache --clear
  make_retry all
  popd
  echo "Merging profraw files..."
  $tools/llvm-current-bak/bin/llvm-profdata merge -output=$profdata $profiles/*.profraw
  echo "wrote $profdata."
else
  echo "Skipping profdata generation as it is already built."
fi

# Restore llvm-current to the stage 1 (non-instrumented) build.
pushd "$tools"
rm -f llvm-current
mv llvm-current-bak llvm-current
popd

# ---------------------------------------------------------------
#                            Stage 3
# ---------------------------------------------------------------
# Stage 3. Build clang with profile-guided optimizations
#          (PGO), using clang.
if [[ ! -e "$tools/llvm-pgo-current" ]]; then
  ./clang.sh --use-clang=$HOME/dev/tools/llvm-current \
             --skip-confirmation                      \
             --clang-opts                             \
             --use-commit="$tag"                      \
             --with-pgo=$profdata
  pushd $HOME/dev/tools
  new_llvm="$(basename $(readlink -f llvm-current))"
  ln -s $new_llvm llvm-pgo-current
  popd
else
  echo "Skipping stage 3 as it is already built."
fi

# At this point, both llvm-current and llvm-pgo-current should
# point to the latest (PGO-optimized) build.