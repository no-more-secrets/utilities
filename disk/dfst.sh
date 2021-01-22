#!/bin/bash
set -e
set -o pipefail

# df -h -P command sorted on given column.
__dfs() {
    local sort_by=$1
    local cmd='df -h -P'
    # First print column headers
    $cmd | head -n1
    $cmd | tail -n +2 | sort -k${sort_by}hr
}

# df -h -P command sorted by total storage.
dfst() { __dfs 2; }

dfst