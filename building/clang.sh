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

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Set this flag to control whether ot use svn or git. SVN is
# preferred because it is the primary repo and it allows us to
# use a consistent revision number for all sub projects. It also
# allows us to get the release candidate number. Git has the
# advantage that it is faster to checkout and potentially more
# reliable on wonky network connections. But if time is not a
# concern, then SVN should be used.
use_git=0

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Command line parameters

[[ "$1" =~ --trunk.* ]] && trunk=1 || trunk=0
[[ "$1" =~ --trunk=([0-9]+) ]] && rev=${BASH_REMATCH[1]}

check_confirm_install() {
  [[ -z "$suffix"  ]] && die "suffix variable not populated."
  [[ -z "$version" ]] && die "version variable not populated."

  install=$HOME/dev/tools/llvm-$suffix
  [[ -d "$install" ]] && die "$install already exists."

  echo
  echo "Will install:"
  echo
  echo "  LLVM/clang version: $version"
  echo
  echo "  To folder: $install"
  echo
  echo -n "Press enter to continue..."
  read
}

if (( use_git )); then
  llvm_github="https://github.com/llvm-mirror"
  git_branch=master
  suffix=$(date +"%Y-%m-%d-%M.%H.%S")
  version=$suffix

  git_clone() {
    local dir=$1
    local repo=$2
    local target=$3
    [[ -z "$target" ]] && target="$repo"
    old_dir=$(pwd)
    cd $dir
    git clone --depth=1 --branch=$git_branch $llvm_github/$repo.git $target
    cd "$old_dir" # do this because `cd .` --> `cd -` doesn't work.
  }

  check_confirm_install
  cd $work

  git_clone  .                       llvm
  git_clone  llvm/tools              clang
  git_clone  llvm/tools              lld
  git_clone  llvm/tools/clang/tools  clang-tools-extra  extra
  git_clone  llvm/projects           libcxx
  git_clone  llvm/projects           libcxxabi
  git_clone  llvm/projects           compiler-rt

else # use SVN
  # Get global head revision of repo as a default.  This
  # should be fine whether trunk or tag is being built.
  rev=$(svn info --show-item=revision http://llvm.org/svn/llvm-project)

  if (( trunk )); then
      repo_root=trunk
      release=trunk
      [[ -z "$rev" ]] && rev=$(svn info --show-item=revision http://llvm.org/svn/llvm-project/llvm/trunk)
      suffix=trunk-r$rev
      candidate=
      version="$suffix"
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
      version="$release/$candidate"
  fi

  llvm_svn="http://llvm.org/svn/llvm-project"
  svn_co() {
    local dir=$1
    local repo=$2
    local target=$3
    [[ -z "$target" ]] && target="$repo"
    old_dir=$(pwd)
    cd $dir
    svn co -r$rev $llvm_svn/$repo/$repo_root $target
    cd "$old_dir" # do this because `cd .` --> `cd -` doesn't work.
  }

  check_confirm_install
  cd $work

  svn_co     .                       llvm
  svn_co     llvm/tools              cfe                clang
  svn_co     llvm/tools              lld
  svn_co     llvm/tools/clang/tools  clang-tools-extra  extra
  svn_co     llvm/projects           libcxx
  svn_co     llvm/projects           libcxxabi
  svn_co     llvm/projects           compiler-rt
fi

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
#ninja check-libcxx # FIXME enable these?
#ninja check-libcxxabi # FIXME enable these?
ninja install

# Now create a symlink to the one we just built.
cd $(dirname $install) # folder containing all the llvm-*
link='llvm-current'
rm -f "$link"
ln -s llvm-$suffix $link
