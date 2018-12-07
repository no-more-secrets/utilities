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

# Get global head revision of repo as a default.  This
# should be fine whether trunk or tag is being built.
rev=$(svn info --show-item=revision http://llvm.org/svn/llvm-project)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Command line parameters

[[ "$1" =~ --trunk.* ]] && trunk=1 || trunk=0
[[ "$1" =~ --trunk=([0-9]+) ]] && rev=${BASH_REMATCH[1]}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if (( trunk )); then
    repo_root=trunk
    release=trunk
    [[ -z "$rev" ]] && rev=$(svn info --show-item=revision http://llvm.org/svn/llvm-project/llvm/trunk)
    suffix=trunk-r$rev
    candidate=
else
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
fi

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

svn co -r$rev http://llvm.org/svn/llvm-project/llvm/$repo_root llvm

cd llvm/tools
svn co -r$rev http://llvm.org/svn/llvm-project/cfe/$repo_root clang
cd ../../

cd llvm/tools
svn co -r$rev http://llvm.org/svn/llvm-project/lld/$repo_root lld
cd ../../

cd llvm/tools/clang/tools
svn co -r$rev http://llvm.org/svn/llvm-project/clang-tools-extra/$repo_root extra
cd ../../../../

cd llvm/projects
svn co -r$rev http://llvm.org/svn/llvm-project/libcxx/$repo_root libcxx
cd ../..

cd llvm/projects
svn co -r$rev http://llvm.org/svn/llvm-project/libcxxabi/$repo_root libcxxabi
cd ../..

cd llvm/projects
svn co -r$rev http://llvm.org/svn/llvm-project/compiler-rt/$repo_root compiler-rt
cd ../..

# This option would tell it where the libstdc++ is that it would use.
# -DGCC_INSTALL_PREFIX=

# -DCMAKE_C_COMPILER=$HOME/dev/tools/llvm-current/bin/clang
# -DCMAKE_CXX_COMPILER=$HOME/dev/tools/llvm-current/bin/clang++

# -DLIBCXX_CXX_ABI=libstdc++

cmake_vars="
  -DCMAKE_BUILD_TYPE=Release
  -DCOMPILER_RT_INCLUDE_TESTS=OFF
  -DLLVM_ENABLE_ASSERTIONS=OFF
  -DCMAKE_INSTALL_PREFIX=$install
"

mkdir build
cd build
cmake -G Ninja $cmake_vars ../llvm

ninja
ninja check-clang check-lld
#ninja check-libcxx
#ninja check-libcxxabi
ninja install

# Now create a symlink to the one we just built.
cd $(dirname $install) # folder containing all the llvm-*
link='llvm-current'
rm -f "$link"
ln -s llvm-$suffix $link
