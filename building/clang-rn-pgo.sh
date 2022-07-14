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

cd "$(dirname "$(readlink -f "$0")")"

tools=$HOME/dev/tools
profdata=/tmp/rn-profdata.prof

# If we got interrupted, restore llvm-current to the stage 1.
pushd "$tools"
if [[ -e llvm-current-bak ]]; then
  rm -f llvm-current
  mv llvm-current-bak llvm-current
fi
popd

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
  rm -rf /tmp/revolution-now-game
  git clone ssh://git@github.com/dpacbach/revolution-now-game \
            /tmp/revolution-now-game --recursive
  pushd /tmp/revolution-now-game
  # Note at this point llvm-current points to the instrumented
  # build.
  cmc --clang --lld --libstdcxx --asan --release
  ccache --clear
  make all
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