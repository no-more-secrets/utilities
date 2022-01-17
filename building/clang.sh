#!/bin/bash
# ---------------------------------------------------------------
#                          LLVM / Clang
# ---------------------------------------------------------------
set -e
set -o pipefail

# ---------------------------------------------------------------
# Includes
# ---------------------------------------------------------------
source util.sh

# ---------------------------------------------------------------
#                       Create Work Areas
# ---------------------------------------------------------------
cd /tmp
work=clang-build
[[ -d $work ]] && /bin/rm -rf "$work"
mkdir -p $work

die() {
  echo "$@" >&2
  exit 1
}

tools="$HOME/dev/tools"
mkdir -p "$tools"

# ---------------------------------------------------------------
#                    Command Line Arguments
# ---------------------------------------------------------------
usage_exit() {
  echo "Usage: $0 <options>"
  echo
  echo "  Options:"
  echo
  echo "    --use-clang:  Build with clang.  This can be set to the llvm root"
  echo "                  or left empty for ~/dev/tools/llvm-current."
  echo "    --clang-opts: Enable LTO and the new pass manager."
  echo "    --with-inst:  Build clang with instrumentation."
  echo "    --with-pgo:   Build with profile-guided optimizations."
  echo "                  This requires specifying a pgo file."
  echo "    --skip-confirmation: Don't wait for the user to hit enter before"
  echo "                  proceeding with the build."
  echo "    --skip-tests  Don't run 'make check'."
  echo "    --no-retry    Do not retry on failed build."
  echo "    --use-commit  Checkout the given commit."
  echo
  exit 1
}

while [[ $# > 0 ]]; do
  arg=$1
  shift
  has_arg=0
  [[ "$arg" =~ = ]] && {
    has_arg=1
    arg="${arg//=/ }"
    set -- $arg "$@"
    arg=$1
    shift
  }
  case $arg in
    --help)
      usage_exit
      ;;
    --use-clang)
      if (( has_arg )); then
        use_clang="$1"
        shift
      else
        use_clang="$tools/llvm-current"
      fi
      [[ -x "$use_clang/bin/clang" ]] || \
        die "use_clang: invalid llvm root folder: $use_clang."
      ;;
    --no-retry)
      no_retry=1
      ;;
    --clang-opts)
      clang_opts=1
      ;;
    --with-inst)
      with_inst=1
      ;;
    --skip-tests)
      skip_tests=1
      ;;
    --skip-confirmation)
      skip_confirmation=1
      ;;
    --use-commit)
      use_commit="$1"
      [[ -z "$use_commit" ]] && die "use_commit: must take a value."
      shift
      ;;
    --with-pgo)
      with_pgo="$1"
      [[ -f "$with_pgo" ]] || \
        die "with_pgo: value must be valid prof file; '$with_pgo' does not exist."
      shift
      ;;
    *)
      echo "Unrecognized argument $arg."
      usage_exit
      ;;
  esac
done

requires_arg() {
  arg_name="$1"
  eval "arg_val=\$$arg_name"
  arg_name2="$2"
  eval "arg_val2=\$$arg_name2"
  if [[ ! -z "$arg_val" && "$arg_val" != "0" ]]; then
    if [[ -z "$arg_val2" || "$arg_val2" == "0" ]]; then
      die "--${arg_name//_/-} requires --${arg_name2//_/-}."
    fi
  fi
  return 0
}

requires_not_arg() {
  arg_name="$1"
  eval "arg_val=\$$arg_name"
  arg_name2="$2"
  eval "arg_val2=\$$arg_name2"
  if [[ ! -z "$arg_val" && "$arg_val" != "0" ]]; then
    if [[ ! -z "$arg_val2" && "$arg_val2" != "0" ]]; then
      die "--${arg_name//_/-} cannot be used with --${arg_name2//_/-}."
    fi
  fi
  return 0
}

requires_arg clang_opts use_clang
requires_arg with_inst  use_clang
requires_arg with_pgo   use_clang

requires_not_arg with_pgo  with_inst
requires_not_arg with_inst with_pgo

# ---------------------------------------------------------------
#                       Version Checking
# ---------------------------------------------------------------
suffix=$(date +"%Y-%m-%d-%M.%H.%S")
(( with_inst )) && suffix="instrumented-$suffix"
[[ ! -z "$with_pgo" ]] && suffix="pgo-$suffix"
[[ -z "$suffix"  ]] && die "suffix variable not populated."

install=$HOME/dev/tools/llvm-$suffix
[[ -d "$install" ]] && die "$install already exists."

version="$suffix"
echo
echo "Will install:"
echo
echo "  LLVM/clang version: $version"
echo
echo "  To folder: $install"
echo
echo "    use_clang:  $use_clang"
echo "    clang_opts: $clang_opts"
echo "    with_inst:  $with_inst"
echo "    with_pgo:   $with_pgo"
echo
(( ! skip_confirmation )) && {
echo -n "Press enter to continue..."
read
}
cd $work

# This option would tell it where the libstdc++ is that it would use.
# -DGCC_INSTALL_PREFIX=
# -DLIBCXX_CXX_ABI=libstdc++

# ---------------------------------------------------------------
#                       Build CMake Command
# ---------------------------------------------------------------
subprojects='clang;clang-tools-extra;libcxx;libcxxabi;compiler-rt'
[[ "$(uname)" != Darwin ]] && subprojects="$subprojects;lld"

cmake_add() {
  local key="$1"
  local value="$2"
  cmake_vars="$cmake_vars -D$key=$value"
}

cmake_vars=""

cxx_flags=
c_flags=

cmake_add CMAKE_BUILD_TYPE          Release
cmake_add COMPILER_RT_INCLUDE_TESTS OFF
cmake_add LLVM_ENABLE_ASSERTIONS    OFF
cmake_add LLVM_ENABLE_PROJECTS      $subprojects
cmake_add CMAKE_INSTALL_PREFIX      $install

# This is needed so that the profile output files can be written
# and read in a compressed manner (hence both the instrumentation
# build and normal builds of clang need this). We need to use
# FORCE_ON because if we just use ON then the CMake files will
# silently set it to OFF if it cannot find zlib on the system,
# which we don't want.
cmake_add LLVM_ENABLE_ZLIB          FORCE_ON
# On debian CMake somehow loses the ability to find zlib under
# circumstances whose conditions are not understood, and this
# seems to fix it, though shouldn't hurt on other platforms.
libz=/usr/lib/x86_64-linux-gnu/libz.so
[[ -e "$libz" ]] && cmake_add ZLIB_LIBRARY "$libz"

[[ ! -z "$use_clang" ]] && {
  cmake_add CMAKE_C_COMPILER   "$use_clang/bin/clang"
  cmake_add CMAKE_CXX_COMPILER "$use_clang/bin/clang++"
  cmake_add LLVM_USE_LINKER    "lld"
}

(( clang_opts )) && {
  cxx_flags="$cxx_flags -fexperimental-new-pass-manager"
  cmake_add LLVM_ENABLE_LTO "Thin"
}

# https://llvm.org/docs/HowToBuildWithPGO.html
(( with_inst )) && {
  cmake_add LLVM_BUILD_INSTRUMENTED "IR"
  cmake_add LLVM_BUILD_RUNTIME      "YES"
}

[[ ! -z "$with_pgo" ]] && {
  cmake_add LLVM_PROFDATA_FILE "$with_pgo"
  cxx_flags="$cxx_flags -Wno-backend-plugin"
  c_flags="$c_flags -Wno-backend-plugin"
}

# ---------------------------------------------------------------
#                         Clone Git Repo
# ---------------------------------------------------------------
llvm_github="https://github.com/llvm"
repo='llvm-project'
if [[ ! -z "$use_commit" ]]; then
  git clone $llvm_github/$repo.git
  cd $repo
  git checkout "$use_commit"
  cd -
else
  # llvm now uses "main" instead of "master".
  git clone --depth=1 --branch=main $llvm_github/$repo.git
fi
cd $repo

# ---------------------------------------------------------------
#                          Run CMake
# ---------------------------------------------------------------
[[ "$(uname)" == Darwin ]] && {
  export CFLAGS="-I/opt/local/include"
  export CXXFLAGS="-I/opt/local/include"
}

mkdir build
cd build
# Do the c/cxx flags here because their values may contain spaces
# in them.
run_cmake -G Ninja                       \
          -Wno-dev                       \
           $cmake_vars                   \
          -DCMAKE_CXX_FLAGS="$cxx_flags" \
          -DCMAKE_C_FLAGS="$c_flags"     \
          ../llvm

# ---------------------------------------------------------------
#                        Build/Test/Install
# ---------------------------------------------------------------
# On some machines the build fails with internal compiler errors
# (such as segfaults) that seem to go away on retries (??).
ninja_retry() {
  local target="$1"
  local cmd
  [[ ! -z "$target" ]] && cmd="ninja $target" || cmd=ninja
  while true; do
    $cmd && break
    (( no_retry )) && die "failed to build (target \"$target\")."
    sleep 60
  done
}

ninja_retry
(( ! skip_tests )) && {
  ninja_retry check-clang
  [[ "$(uname)" != Darwin ]] && ninja_retry check-lld
  #ninja_retry check-libcxx # FIXME enable these?
  #ninja_retry check-libcxxabi # FIXME enable these?
}

# No retry here.
ninja install

# ---------------------------------------------------------------
#                        Create Symlinks
# ---------------------------------------------------------------
# Now create a symlink to the one we just built.
cd $(dirname $install) # folder containing all the llvm-*
link='llvm-current'
rm -f "$link"
ln -s llvm-$suffix $link

cd ~/bin
rm -f clang-format
ln -s $tools/llvm-current/bin/clang-format clang-format
