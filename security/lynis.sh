#!/bin/bash
# This script clones the latest version of the Lynis server secu-
# rity scanning tool and runs it as root. It will scan the entire
# system for any security vulnerabilities. Strangely, the github
# repo includes the binary directly.
set -eo pipefail

if (( EUID != 0 )); then
  echo "Please run as root."
  exit 1
fi

working_dir=lynis-clone

cd /tmp
rm -rf "$working_dir"

git clone --quiet https://github.com/CISOfy/lynis "$working_dir"

cd "$working_dir"
[[ -x ./lynis ]]

echo "=========================================================="
echo "Running Lynis version $(./lynis --version)"
echo "=========================================================="

# Now run the audit.
./lynis audit system