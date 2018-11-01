#!/bin/bash
set -e
set -x
set -o pipefail

# =======================================================================
# Things to change
# =======================================================================
  version=0.8.0
  checksum=8223d01a27ddf427e6833d826e631cf1e3b9f70185f7c66684e57339096afea5
# =======================================================================

install_to=$HOME/dev/tools/build2-$version

die() {
  echo "$@" >&2
  exit 1
}

end() {
  echo "$@"
  exit 0
}

[[ -d $install_to ]] && end "build2 version $version already installed."

cd /tmp

work=build-build2

[[ -d $work ]] && /bin/rm -rf "$work"
mkdir -p $work
cd $work

curl -sSfO https://download.build2.org/$version/build2-install-$version.sh

[[ -f build2-install-$version.sh ]]

sum=$(sha256sum build2-install-$version.sh | awk '{print $1}')

[[ "$sum" == "$checksum" ]] || die "checksum does not match!"

sh build2-install-$version.sh $install_to
