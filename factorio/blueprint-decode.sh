#!/bin/bash
# Input:  Factorio Blueprint string.
# Output: Minified Json.
#
# NOTE: zlib-flate is in the `qpdf` package. To pretty-print the
# json, pass the output of this program to `json_pp`.
set -e
set -o pipefail

cat                        \
  | tail -c +2             \
  | base64 -d              \
  | zlib-flate -uncompress