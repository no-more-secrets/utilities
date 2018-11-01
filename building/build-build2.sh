#!/bin/bash
set -e
set -o pipefail

die() {
  echo "$@" >&2
  exit 1
}

end() {
  echo "$@"
  exit 0
}

# Assumes that there is a file call toolchain.sha256 and that the first line
# looks like:
#     # 0.8.0
version=$(wget -qO- 'https://download.build2.org/toolchain.sha256' | awk 'NR==1 { print $2 }')
echo "found latest version: $version"

install_to=$HOME/dev/tools/build2-$version

if [[ ! -d $install_to ]]; then
  echo "build2 version $version not already installed. Installing..."

  cd /tmp

  work=build-build2

  [[ -d $work ]] && /bin/rm -rf "$work"
  mkdir $work
  cd $work

  curl -sSfO https://download.build2.org/$version/build2-install-$version.sh

  [[ -f build2-install-$version.sh ]]

  sh build2-install-$version.sh $install_to
else
  echo "build2 version $version already installed."
fi

echo "[re]creating links"

create_link() {
  binary=$1
  from="$install_to/bin/$1"
  to="$HOME/bin/$1"
  rm -f "$to"
  ln -s "$from" "$to"
  echo "$from --> $to"
}

create_link b
create_link bdep
create_link bpkg
