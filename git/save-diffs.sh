#!/bin/bash
# This script will save the current changes to the stash.
set -eo pipefail

# There is also the "git stash create" + "git stash store" method
# which won't touch the timestamps on the files, but it seems
# that unfortunately it doesn't work with untracked files.
git stash push --include-untracked -m "backup of local changes: $(date)"
git stash apply --quiet
echo ---------------------------------------------------------------------------
git stash list | head