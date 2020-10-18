#!/bin/bash
set -e
set -o pipefail

cd /tmp

work=clang-build

[[ -d $work ]] && /bin/rm -rf "$work"
mkdir -p $work

die() {
  echo "$@" >&2
  exit 1
}

suffix=$(date +"%Y-%m-%d-%M.%H.%S")
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
echo -n "Press enter to continue..."
read
cd $work

llvm_github="https://github.com/llvm"
repo='llvm-project'
git clone --depth=1 --branch=master $llvm_github/$repo.git
cd $repo

# This option would tell it where the libstdc++ is that it would use.
# -DGCC_INSTALL_PREFIX=

# -DCMAKE_C_COMPILER=$HOME/dev/tools/llvm-current/bin/clang
# -DCMAKE_CXX_COMPILER=$HOME/dev/tools/llvm-current/bin/clang++

# -DLIBCXX_CXX_ABI=libstdc++

subprojects='clang;clang-tools-extra;libcxx;libcxxabi;compiler-rt;lld'

cmake_vars="
  -DCMAKE_BUILD_TYPE=Release
  -DCOMPILER_RT_INCLUDE_TESTS=OFF
  -DLLVM_ENABLE_ASSERTIONS=OFF
  -DLLVM_ENABLE_PROJECTS=$subprojects
  -DCMAKE_INSTALL_PREFIX=$install
"

[[ "$(uname)" == Darwin ]] && {
  export CFLAGS="-I/opt/local/include"
  export CXXFLAGS="-I/opt/local/include"
}

mkdir build
cd build
cmake -G Ninja $cmake_vars ../llvm

ninja
ninja check-clang check-lld
#ninja check-libcxx # FIXME enable these?
#ninja check-libcxxabi # FIXME enable these?
ninja install

# Now create a symlink to the one we just built.
cd $(dirname $install) # folder containing all the llvm-*
link='llvm-current'
rm -f "$link"
ln -s llvm-$suffix $link

cd ~/bin
rm -f clang-format
ln -s $HOME/dev/tools/llvm-current/bin/clang-format clang-format
