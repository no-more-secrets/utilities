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

gstt() {
  grep $1 | sort -V | tail -n1 | tr -d '/'
}

# Get latest llvm version
release=$(svn ls http://llvm.org/svn/llvm-project/llvm/tags | gstt RELEASE_)
[[ "$release" =~ RELEASE_[0-9]+ ]] || die "release $release has unexpected form."

candidates=$(svn ls http://llvm.org/svn/llvm-project/llvm/tags/$release)

if [[ "$candidates" =~ final ]]; then
    candidate=final
else
    candidate=$(svn ls http://llvm.org/svn/llvm-project/llvm/tags/$release | gstt rc)
fi

repo_root=tags/$release/$candidate
suffix=v${release/RELEASE_}.$candidate
install=$HOME/dev/tools/llvm-$suffix

[[ -d "$install" ]] && die "$install already exists."

echo
echo "Will install:"
echo
echo "  LLVM/clang version: $release/$candidate"
echo
echo "  To folder: $install"
echo
echo -n "Press enter to continue..."
read

cd $work

svn co http://llvm.org/svn/llvm-project/llvm/$repo_root llvm

cd llvm/tools
svn co http://llvm.org/svn/llvm-project/cfe/$repo_root clang
cd ../../

cd llvm/tools/clang/tools
svn co http://llvm.org/svn/llvm-project/clang-tools-extra/$repo_root extra
cd ../../../../

# Check out Compiler-RT (optional):
#cd llvm/projects
#svn co http://llvm.org/svn/llvm-project/compiler-rt/$repo_root compiler-rt
#cd ../..

# This option would tell it where the libstdc++ is that it would use.
# -DGCC_INSTALL_PREFIX=

cmake_vars="
  -DCMAKE_BUILD_TYPE=Release
  -DCMAKE_INSTALL_PREFIX=$install
"

mkdir build
cd build
cmake -G "Unix Makefiles" $cmake_vars ../llvm

if which nproc 2>/dev/null; then
    threads=$(nproc --all)
else
    threads=5
fi

make -j$threads

make -j$threads check-clang # optional

make install
