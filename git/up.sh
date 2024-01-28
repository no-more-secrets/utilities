#!/bin/bash
set -eo pipefail

pull() {
  local where="$1"
  local branch="$2"
  cd "$where"
  echo -en "$(basename "$where"):\t"
  git fetch origin "$branch" --quiet
  # If there are conflicts then we want it to fail and not mess
  # things up, so just disable the auto-stash, otherwise in some
  # cases it doesn't even return an error if there is a conflict.
  git merge "origin/$branch" --no-autostash
}

pull ~/dev/utilities master
pull ~/dev/moonlib   main
pull ~/.dotfiles     master