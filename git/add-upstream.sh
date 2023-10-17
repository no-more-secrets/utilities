#!/bin/bash
set -e
set -o pipefail

die() {
  echo 1>&2 "$@"
  exit 1
}

{ git remote -v show | grep upstream; } >/dev/null \
  && die 'upstream already added.'

{ git remote -v show | grep no-more-secrets | grep '^origin'; } >/dev/null \
  || die 'origin is not from the no-more-secrets account.'

# The `git remote -v show` command will produce an output like:
#
#   origin  git@github.com:no-more-secrets/sol2 (fetch)
#   origin  git@github.com:no-more-secrets/sol2 (push)
#
repo="$(git remote -v show | awk '{print $2}' | awk -F/ '{print $NF}' | sort -u)"

[[ -z "$repo" ]] && die "failed to find repo."
repo=${repo//.git/}

py_code='
import json, sys
j = json.loads( sys.stdin.read() )
print( j["parent"]["full_name"] )
'

forked_acct_repo="$(curl -s "https://api.github.com/repos/no-more-secrets/$repo" | python3 -c "$py_code")"

parent_repo="https://no-more-secrets@github.com/$forked_acct_repo"

echo "Adding new remote 'upstream' pointing to:"
echo
echo "  $parent_repo"
echo

git remote add upstream "$parent_repo"