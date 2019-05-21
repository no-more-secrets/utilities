#!/bin/bash
# This script will checkout and build the latest tag of Rosegarden.
set -e
set -o pipefail

script_dir=$(cd $(dirname $0) && pwd)
echo "script directory: $script_dir"

. $script_dir/util.sh

sudo apt install libjack-dev    \
                 ladspa-sdk-dev \
                 dssi-dev       \
                 liblo-dev      \
                 liblrdf-dev

latest_tag=$(svn ls http://svn.code.sf.net/p/rosegarden/code/tags | grep rosegarden- | sort -V | tail -n1)
echo "latest tag: $latest_tag"

svn co http://svn.code.sf.net/p/rosegarden/code/tags/$latest_tag

cd $latest_tag

mkdir build

cd build

cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo

make -j$(build_threads)
