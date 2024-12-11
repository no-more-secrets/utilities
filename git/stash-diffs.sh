#!/bin/bash
# This script will stash the current changes to the stash without
# touching their timestamps.
set -e

# We use the "git stash create" + "git stash store" method in-
# stead of "git stash push" + "git stash apply" because the
# former will not touch the timestamsp on the files. However, the
# former has the disadvantage that it does not work with un-
# tracked files.
hash=$(git stash create)
git stash store -m "backup of local changes: $(date)" "$hash"
echo ---------------------------------------------------------------------------
git stash list | head