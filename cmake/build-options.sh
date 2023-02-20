#!/bin/bash
set -e

source ~/dev/utilities/bashlib/util.sh

add_option() { options="$options\n$1"; }

options="Update"
add_option "All Platforms"
add_option "Debug & Release"
add_option "Debug & Release (gcc)"
add_option "Current"

select_answer() { echo -e "$options" | fzf; }

answer=$(select_answer)

print_bar() {
  n=$1
  for (( i=0; i < $n; i++ )); do
    echo -n '-'
  done
}

print_title_bar() {
  title="$1"
  len_title="${#title}"
  half="$(( ( COLUMNS - len_title - 2 )/2 ))"
  print_bar $half
  echo -en " ${c_green}${s_bold}$title$c_norm "
  print_bar $half
  echo
}

build_and_test() {
  platform="$(basename $(readlink -f .builds/current))"
  print_title_bar "$platform"
  make all
  make test
}

restore() { cmc --clang --lld --libstdcxx --release --cached; }

case "$answer" in
  "Update")
    clear
    git pull origin `git rev-parse --abbrev-ref HEAD` --quiet
    git submodule sync --quiet
    git submodule update --init
    build_and_test
    ;;
  "All Platforms")
    ~/dev/utilities/cmake/build-all-platforms.sh
    ;;
  "Debug & Release")
    clear
    cmc --clang --lld --libstdcxx --asan;    build_and_test
    cmc --clang --lld --libstdcxx --release; build_and_test
    ;;
  "Debug & Release (gcc)")
    clear
    cmc --gcc=current --libstdcxx --asan;    build_and_test
    cmc --gcc=current --libstdcxx --release; build_and_test
    ;;
  "Current")
    clear
    cmc rc; build_and_test
    ;;
  *)
    die "unrecognized option: $answer"
    ;;
esac

restore