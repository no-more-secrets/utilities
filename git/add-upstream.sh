#!/bin/bash
set -e
set -o pipefail

die() {
  echo 1>&2 "$@"
  exit 1
}

{ git remote -v show | grep upstream; } >/dev/null \
  && die 'upstream already added.'

{ git remote -v show | grep dpacbach | grep '^origin'; } >/dev/null \
  || die 'origin is not from the dpacbach account.'

# The `git remote -v show` command will produce an output like:
#
#   origin  git@github.com:dpacbach/sol2 (fetch)
#   origin  git@github.com:dpacbach/sol2 (push)
#
repo="$(git remote -v show | awk '{print $2}' | awk -F/ '{print $NF}' | sort -u)"

[[ -z "$repo" ]] && die "failed to find repo."
repo=${repo//.git/}

py_code='
import json, sys
j = json.loads( sys.stdin.read() )
print( j["parent"]["full_name"] )
'

forked_acct_repo="$(curl -s "https://api.github.com/repos/dpacbach/$repo" | python -c "$py_code")"

parent_repo="https://dpacbach@github.com/$forked_acct_repo"

echo "Adding new remote 'upstream' pointing to:"
echo
echo "  $parent_repo"
echo

git remote add upstream "$parent_repo"