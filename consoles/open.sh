#!/bin/bash
set -e
set -o pipefail

source ~/dev/utilities/bashlib/util.sh

name="$1"

this="$(dirname "$(readlink -f $0)")"
cd "$this"
# Make sure we are in the right directory.
[[ -d lib ]]

[[ -z "$name" ]] && \
  die "must enter layout name as first argument."

layout_file="layouts/$name.lua"
[[ -f "$layout_file" ]] || \
  die "cannot find layout file $layout_file."

shell_code="$(cat "$layout_file" | lua lib/create-layout.lua)"

echo "$shell_code" | sh