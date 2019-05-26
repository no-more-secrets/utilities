#!/bin/bash
set -e
set -o pipefail

cd $(dirname $0)

res=$(cat data/general-midi.txt | fzf)

echo $res
