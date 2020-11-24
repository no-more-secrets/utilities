#!/bin/bash

# Usage Examples:
#   cloc_cpp_rank *.cpp # all cpp files
#   cloc_cpp_rank */    # all folders
{ echo --------------------------------------------- -------------
  echo File/Folder Lines-of-C++
  echo --------------------------------------------- -------------
  for d in "$@"; do
      echo -n "$d "
      if ! { cloc $d 2>/dev/null | grep -E '^(C/)?C\+\+'; }; then
          echo _ _ _ _ 0
      fi
  done | awk '{print $6, $1}' \
       | sort -nr             \
       | awk '{print $2, $1}'
  echo --------------------------------------------- -------------
} | awk '{ count += $2; print } END { print "Total", count }' \
  | awk '{ print } END { print "--------------------------------------------- -------------" }' \
  | column -t --output-separator='' | grep -v ' 0$'