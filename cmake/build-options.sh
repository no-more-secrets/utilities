#!/bin/bash
set -e

source ~/dev/utilities/bashlib/util.sh

add_line() { options="$options\n$1"; }

options="Build Options Menu"
add_line "----------------------------------------"
add_line "Update & Build (release)"
add_line "Update & Build (current)"
add_line "Update & Build Debug & Release (clang)"
add_line "Update & Build All Platforms"
add_line "Build All Platforms"
add_line "Build Debug & Release (clang)"
add_line "Build Debug & Release (gcc)"
add_line "Build/Run Tests & Game (current)"
add_line "Build/Run Game (no tests)"
add_line "Restore Default Configuration"

fzf() {
  command fzf            \
    --header-lines=2     \
    --header-first       \
    --info=hidden        \
    --height="~100"      \
    --disabled           \
    --bind='j:down'      \
    --bind='k:up'        \
    --border=rounded
}

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

update() {
  git pull origin `git rev-parse --abbrev-ref HEAD` --quiet
  git submodule sync --quiet
  git submodule update --init
}

restore() { cmc --clang --lld --libstdcxx --release --cached; }

case "$answer" in
  "Update & Build (release)")
    update
    clear
    cmc --clang --lld --libstdcxx --release; build_and_test
    ;;
  "Update & Build (current)")
    update
    clear
    build_and_test
    ;;
  "Update & Build Debug & Release (clang)")
    update
    clear
    cmc --clang --lld --libstdcxx --asan;    build_and_test
    cmc --clang --lld --libstdcxx --release; build_and_test
    ;;
  "Update & Build All Platforms")
    update
    clear
    ~/dev/utilities/cmake/build-all-platforms.sh
    ;;
  "Build All Platforms")
    ~/dev/utilities/cmake/build-all-platforms.sh
    ;;
  "Build Debug & Release (clang)")
    clear
    cmc --clang --lld --libstdcxx --asan;    build_and_test
    cmc --clang --lld --libstdcxx --release; build_and_test
    ;;
  "Build Debug & Release (gcc)")
    clear
    cmc --gcc=current --libstdcxx --asan;    build_and_test
    cmc --gcc=current --libstdcxx --release; build_and_test
    ;;
  "Build/Run Tests & Game (current)")
    build_and_test
    make game
    ;;
  "Build/Run Game (no tests)")
    make game
    ;;
  "Restore Default Configuration")
    ;;
  *)
    die "unrecognized option: $answer"
    ;;
esac

restore