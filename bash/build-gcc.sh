#!/bin/bash
set -eE
set -o pipefail

# ╔═════════════════════════════════════════════════════════════╗
# ║                        Change these                         ║
# ╚═════════════════════════════════════════════════════════════╝
# Version  to be checked out. There should be a corresponding tag
# in the repo called gcc-$version-release.
version=7_2_0
# How many threads to use during compilation.
threads=4
# The gcc folder will be placed inside this one.
install_to="/Users/dsicilia/dev/tools"
# Should be gcc (not clang as it might be on mac).
c_compiler=/opt/local/bin/x86_64-apple-darwin16-gcc-mp-7
cxx_compiler=/opt/local/bin/x86_64-apple-darwin16-g++-mp-7

# ╔═════════════════════════════════════════════════════════════╗
# ║                  Shouldn't Have to Change                   ║
# ╚═════════════════════════════════════════════════════════════╝
program_suffix=${version//_/-}
install_prefix="$install_to/gcc-$program_suffix"
git_repo=git://gcc.gnu.org/git/gcc.git
build_logs=$install_prefix/build_logs
work_prefix=/tmp # may not exist yet
work_folder=gcc  # may not exist yet
work_path=$work_prefix/$work_folder
gcc_deps=$work_path/gcc-deps
languages="c,c++"

export CC=$c_compiler
export CXX=$cxx_compiler

c_norm="\033[00m"
c_green="\033[32m"
c_red="\033[31m"

# ╔═════════════════════════════════════════════════════════════╗
# ║                          Utilities                          ║
# ╚═════════════════════════════════════════════════════════════╝
run() {
    local desc=$1
    local func=$2
    local dots="$desc .........................................."
    local regex='(.{40}).*'
    [[ "$dots" =~ $regex ]]; dots="${BASH_REMATCH[1]}"
    echo -n "$dots "
    mkdir -p $build_logs
    # current_log_file should not be  local  because  it is refer-
    # enced by the die() function.
    current_log_file="$build_logs/${func}.log"
    rm -f $current_log_file
    # Redirect  3  so  that  the  error handler can output to the
    # screen if necessary.
    $func 3>&1 1>>$current_log_file 2>>$current_log_file
    echo -e "${c_green}SUCCESS${c_norm}"
}

die() {
    echo -e "${c_red}FAIL${c_norm}" >&3
    echo >&3
    echo "log file: $current_log_file" >&3
    exit 1
}
trap die ERR

make_check_install() {
    make -j$threads && make check -j$threads && make install
}

# ╔═════════════════════════════════════════════════════════════╗
# ║                       Initialization                        ║
# ╚═════════════════════════════════════════════════════════════╝
init() {
    mkdir -p $install_prefix
    mkdir -p $work_prefix
}

# ╔═════════════════════════════════════════════════════════════╗
# ║                         Clone Repo                          ║
# ╚═════════════════════════════════════════════════════════════╝
clone() {
    cd $work_prefix
    rm -rf $work_folder

    git clone $git_repo $work_folder
    cd $work_folder

    local tag=gcc-$version-release

    git checkout $tag
}

# ╔═════════════════════════════════════════════════════════════╗
# ║                   Download Prerequisites                    ║
# ╚═════════════════════════════════════════════════════════════╝
download_prerequisites() {
    cd $work_path
    mkdir -p $gcc_deps
    bash contrib/download_prerequisites --directory=$gcc_deps
}

# ╔═════════════════════════════════════════════════════════════╗
# ║                   Building Prerequisites                    ║
# ╚═════════════════════════════════════════════════════════════╝
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

# ╔═════════════════════════════════════════════════════════════╗
# ║                          Build gcc                          ║
# ╚═════════════════════════════════════════════════════════════╝
build_gcc() {
    cd $work_path
    mkdir -p build && cd build

    ../configure CC=$c_compiler                \
                 CXX=$cxx_compiler             \
                 --with-gmp=$install_prefix    \
                 --with-mpfr=$install_prefix   \
                 --with-mpc=$install_prefix    \
                 --with-isl=$install_prefix    \
                 --prefix=$install_prefix      \
                 --enable-languages=$languages \
                 --program-suffix=-$program_suffix

    make -j$threads && make install
}

# ╔═════════════════════════════════════════════════════════════╗
# ║                          Test gcc                           ║
# ╚═════════════════════════════════════════════════════════════╝
test_gcc() {
    local gcc=$install_prefix/bin/gcc-$program_suffix
    local gpp=$install_prefix/bin/g++-$program_suffix
    
    # Test version
    $gcc --version
    $gpp --version
    
    local code="
        #include <iostream>

        int main() {
            std::cout << \"Hello from gcc-$program_suffix!\"
                      << std::endl;
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

# ╔═════════════════════════════════════════════════════════════╗
# ║                        Main Program                         ║
# ╚═════════════════════════════════════════════════════════════╝
main() {
    run "initializing"              init
    run "cloning gcc"               clone
    run "downloading prerequisites" download_prerequisites
    run "building gmp"              build_gmp
    run "building isl"              build_isl
    run "building mpfr"             build_mpfr
    run "building mpc"              build_mpc
    run "cloning gcc"               clone
    run "building gcc"              build_gcc
    run "testing gcc"               test_gcc
}

main
