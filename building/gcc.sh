#!/bin/bash
# ---------------------------------------------------------------
# GNU C/C++ Compiler
# ---------------------------------------------------------------
set -eE
set -o pipefail

# Must be done first.
this=$(cd $(dirname $0) && pwd)
cd $this

# ---------------------------------------------------------------
#                           Settings
# ---------------------------------------------------------------
# Should be gcc (not clang as it might be on mac).
c_compiler=/usr/bin/gcc
cxx_compiler=/usr/bin/g++

# When this is 1 it will build a gcc that can only build 64 bit
# binaries.  This is useful because it then won't require that
# the system have 32-bit devel packages installed.  If it is 0,
# then it will attempt to build a gcc that can produce either
# 64- or 32-bit binaries, but you must have the 32 devel files
# and packages installed on the system otherwise the configure
# will fail (and probably the build will take longer when it is
# 0).
only_64bit=1

# ---------------------------------------------------------------
# CLI Params
# ---------------------------------------------------------------
case "$1" in
  "--trunk")
    branch=trunk
    ;;
  "--coroutines")
    branch=coroutines
    ;;
  *)
    branch=release  # pick latest release
    ;;
esac

# ---------------------------------------------------------------
# Includes
# ---------------------------------------------------------------
source util.sh

# ---------------------------------------------------------------
# Initialization
# ---------------------------------------------------------------
# This must be a lowercase short word with no spaces describing
# the software being built. Folders/links will be named with
# this.
project_key="gcc"

tools="$HOME/dev/tools"
mkdir -p "$tools"

# ---------------------------------------------------------------
# Functions
# ---------------------------------------------------------------
latest_github_repo_tag() {
    local acct="$1"
    local repo="$2"
    local api_url="https://api.github.com/repos/$acct/$repo/tags"
    # FROM: "name": "releases/gcc-9.1.0",
    # TO:   9.1.0
    curl --silent $api_url | grep '"name":'                              \
                           | sed -rn 's/.*: "releases\/gcc-(.*)".*/\1/p' \
                           | sort -rV                                    \
                           | head -n1
}

# ---------------------------------------------------------------
# Check version and if it already exists.
# ---------------------------------------------------------------
case "$branch" in
  release)
    # Version to be checked out. There should be a corresponding
    # tag in the repo called gcc-$version-release.
    version=$(latest_github_repo_tag gcc-mirror gcc)
    log "latest version: $version"

    regex='^[0-9]+\.[0-9]+\.[0-9]+$'
    [[ "$version" =~ $regex ]] ||
        die "version \"$version\" does not match regex."
    ;;
  trunk)
    suffix=$(date +"%Y-%m-%d-%M.%H.%S")
    [[ -z "$suffix"  ]] && die "suffix variable not populated."
    version=$suffix
    log "building trunk (master), version $version."
    ;;
  coroutines)
    suffix=coroutines-$(date +"%Y-%m-%d-%M.%H.%S")
    [[ -z "$suffix"  ]] && die "suffix variable not populated."
    version=$suffix
    log "building coroutines branch, version $version."
    ;;
  *)
    die "unhandled branch: $branch."
    ;;
esac

[[ -e "$tools/$project_key-$version" ]] && {
    log "$project_key-$version already exists, activating it."
    version="$version"
    tools_link $project_key
    # no bin_links here.
    #supplemental_install
    exit 0
}

# ---------------------------------------------------------------
#                    Shouldn't Have to Change
# ---------------------------------------------------------------
program_suffix="$version"
install_prefix="$tools/$project_key-$program_suffix"
git_repo=git://gcc.gnu.org/git/gcc.git
build_logs=$install_prefix/build-logs
work_prefix=/tmp # may not exist yet
work_folder=gcc  # may not exist yet
work_path=$work_prefix/$work_folder
gcc_deps=$work_path/gcc-deps
languages="c,c++"

export CC=$c_compiler
export CXX=$cxx_compiler

# Some how the flags in the configure commands that tell gcc
# where dependencies are located (in the install_prefix) still
# doesn't seem to prevent build errors where the build cannot
# locate e.g. libisl, even though it was built and exists in
# the install_prefix.
export LIBRARY_PATH="$install_prefix/lib"
export LD_LIBRARY_PATH="$install_prefix/lib"

c_norm="\033[00m"
c_green="\033[32m"
c_green="\033[32m"
c_red="\033[31m"

# The following flags probably do a bit more than just control
# whether gcc can build 32 bit or not, but that's all we're using
# it for here.
(( only_64bit )) && multilib="--disable-multilib" \
                 || multilib="--enable-multilib"

# ---------------------------------------------------------------
#                              Check
# ---------------------------------------------------------------
fail() {
    echo "$@"
    return 1
}

# Check some things for the user
[[ -x "$c_compiler"   ]] || fail "$c_compiler does not exist."
[[ -x "$cxx_compiler" ]] || fail "$cxx_compiler does not exist."

# ---------------------------------------------------------------
#                            Utilities
# ---------------------------------------------------------------
run() {
    local desc=$1
    local func=$2

    local dots="$desc .........................................."
    local regex='(.{40}).*'
    [[ "$dots" =~ $regex ]]; dots="${BASH_REMATCH[1]}"
    echo -n "$dots "

    local marker="$func.finished"
    # If we have already completed this step then just skip.
    if [[ -f "$build_logs/$marker" ]]; then
        echo -e "${c_green}DONE${c_norm}"
        return 0
    fi

    mkdir -p $build_logs
    # current_log_file should not be  local  because  it is refer-
    # enced by the die() function.
    current_log_file="$build_logs/${func}.log"
    rm -f $current_log_file
    # Redirect  3  so  that  the  error handler can output to the
    # screen if necessary.
    $func 3>&1 1>>$current_log_file 2>>$current_log_file
    echo -e "${c_green}SUCCESS${c_norm}"
    # touch marker file so that we don't repeat this step if
    # we fail and run again.
    touch $build_logs/$func.finished
}

die() {
    echo -e "${c_red}FAIL${c_norm}" >&3
    echo >&3
    echo "log file: $current_log_file" >&3
    exit 1
}
trap die ERR

make_check_install() {
    make -j$(build_threads)       && \
    make check -j$(build_threads) && \
    make install
}

# ---------------------------------------------------------------
#                         Initialization
# ---------------------------------------------------------------
init() {
    mkdir -p $install_prefix
    mkdir -p $work_prefix
}

# ---------------------------------------------------------------
#                           Clone Repo
# ---------------------------------------------------------------
clone() {
    cd $work_prefix

    local repo_branch
    case "$branch" in
      release)
        # Hopefully gcc always follows this convention for mapping
        # version number to tag name.
        repo_branch="releases/gcc-$version"
        ;;
      trunk)
        repo_branch="master"
        ;;
      coroutines)
        repo_branch="devel/c++-coroutines"
        ;;
      *)
        die "unhandled branch: $branch."
        ;;
    esac

    # Don't remove it if it already exists because it takes too
    # long to clone again, so if it exists then just run a git
    # clean on it.

    if [[ ! -d $work_folder ]]; then
        # Do a shallow clone only of the repo_branch
        git clone --depth=1 --branch=$repo_branch $git_repo $work_folder
        cd $work_folder
    else
        cd $work_folder
        # f=force, x=remove ignored files, d=remove directories,
        # f=force (#2) meaning move sub .git folders.
        git clean -fxdf
    fi

    git checkout $repo_branch
}

# Needs to be a different name because we need to perform this
# function twice.
clone2() { clone "$@"; }

# ---------------------------------------------------------------
#                     Download Prerequisites
# ---------------------------------------------------------------
download_prerequisites() {
    cd $work_path
    mkdir -p $gcc_deps
    bash contrib/download_prerequisites --directory=$gcc_deps
}

# ---------------------------------------------------------------
#                     Building Prerequisites
# ---------------------------------------------------------------
build_gmp() {
    cd $gcc_deps && cd $(ls -d gmp-*/)
    mkdir -p build && cd build

    ../configure CC=$c_compiler           \
                 CXX=$cxx_compiler        \
                 --enable-cxx             \
                 --prefix=$install_prefix

    make_check_install
}

build_isl() {
    cd $gcc_deps && cd $(ls -d isl-*/)
    mkdir -p build && cd build

    ../configure CC=$c_compiler                    \
                 CXX=$cxx_compiler                 \
                 --with-gmp-prefix=$install_prefix \
                 --prefix=$install_prefix

    make_check_install
}

build_mpfr() {
    cd $gcc_deps && cd $(ls -d mpfr-*/)
    mkdir -p build && cd build

    ../configure CC=$c_compiler             \
                 CXX=$cxx_compiler          \
                 --with-gmp=$install_prefix \
                 --prefix=$install_prefix

    make_check_install
}

build_mpc() {
    cd $gcc_deps && cd $(ls -d mpc-*/)
    mkdir -p build && cd build

    ../configure CC=$c_compiler              \
                 CXX=$cxx_compiler           \
                 --with-gmp=$install_prefix  \
                 --with-mpfr=$install_prefix \
                 --prefix=$install_prefix

    make_check_install
}

# ---------------------------------------------------------------
#                            Build gcc
# ---------------------------------------------------------------
build_gcc() {
    cd $work_path
    mkdir -p build && cd build

    ../configure CC=$c_compiler                \
                 CXX=$cxx_compiler             \
                 $multilib                     \
                 --with-gmp=$install_prefix    \
                 --with-mpfr=$install_prefix   \
                 --with-mpc=$install_prefix    \
                 --with-isl=$install_prefix    \
                 --prefix=$install_prefix      \
                 --enable-languages=$languages \
                 --program-suffix=-$program_suffix

    make -j$(build_threads) && make install
}

# ---------------------------------------------------------------
#                            Test gcc
# ---------------------------------------------------------------
test_gcc() {
    local gcc=$install_prefix/bin/gcc-$program_suffix
    local gpp=$install_prefix/bin/g++-$program_suffix
    
    # Test version
    $gcc --version
    $gpp --version
    
    local code="
        #include <iostream>

        int main() {
            std::cout << \"Hello from gcc version: \"
                      << __VERSION__ << std::endl;
            return 0;
        }
    "
    local test_folder=$install_prefix/test
    mkdir -p $test_folder && cd $test_folder
    rm -f hello.cpp
    echo "$code" >hello.cpp
    $gpp hello.cpp
    
    ./a.out
}

# ---------------------------------------------------------------
#                          Main Program
# ---------------------------------------------------------------
main() {
    run "initializing"              init
    run "cloning gcc"               clone
    run "downloading prerequisites" download_prerequisites
    run "building gmp"              build_gmp
    run "building isl"              build_isl
    run "building mpfr"             build_mpfr
    run "building mpc"              build_mpc
    run "cloning gcc"               clone2
    run "building gcc"              build_gcc
    run "testing gcc"               test_gcc
}

main

# ---------------------------------------------------------------
# Make symlinks
# ---------------------------------------------------------------
version="$version"
tools_link $project_key
# no bin_link here.
