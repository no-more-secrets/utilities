#!/bin/bash
set -e
set -o pipefail

cd /tmp

work=sdl-build

[[ -d $work ]] && /bin/rm -rf "$work"
mkdir -p $work
cd $work

die() {
  echo "$@" >&2
  exit 1
}

latest_version() {
    local project="$1"
    [[ ! -z "$project" ]] && project="_$project"
    local url="https://www.libsdl.org"
    [[ ! -z "$project" ]] && url="$url/projects/SDL$project"
    url="$url/release/"
    curl --silent "$url" | egrep -o "SDL2$project-[0-9]+\\.[0-9]+\\.[0-9]+\\.tar\\.gz" \
                         | sort -uV                                                    \
                         | egrep -o '[0-9]+\.[0-9]+\.[0-9]+'                           \
                         | tail -n1
}

download_version() {
    local project="$1"
    local version="$2"
    [[ ! -z "$project" ]] && project="_$project"
    local url="https://www.libsdl.org"
    [[ ! -z "$project" ]] && url="$url/projects/SDL$project"
    url="$url/release/SDL2$project-$version.tar.gz"
    curl -sSfO "$url"
}

if which nproc &>/dev/null; then
    threads=$(nproc --all)
else
    threads=4
fi

sdl_projects="image mixer ttf"

for project in '' $sdl_projects; do
    [[ ! -z "$project" ]] && uproject="_$project" || uproject=''
    [[ ! -z "$project" ]] && dproject="-$project" || dproject=''
    version=$(latest_version "$project")
    [[ -z "$project" ]] && {
        # For the baes SDL2 package build we need to record its location
        # because the subproject builds (image, ttf, etc.) will need to
        # know the location of its sdl2-config binary.
        export SDL2_CONFIG="$HOME/dev/tools/sdl/sdl$dproject-$version/bin/sdl2-config"
    }
    [[ -d "$HOME/dev/tools/sdl/sdl$dproject-$version" ]] && {
        echo "sdl$dproject-$version already installed."
        continue
    }
    echo "downloading SDL2$uproject version $version"
    download_version "$project" "$version"
    tar xvf "SDL2$uproject-$version.tar.gz"
    pushd "SDL2$uproject-$version"
    ./configure --prefix="$HOME/dev/tools/sdl/sdl$dproject-$version"
    make -j$threads install
    popd
    pushd "$HOME/dev/tools/sdl"
    rm -f "sdl$dproject-current"
    ln -s "sdl$dproject-$version" "sdl$dproject-current"
    popd
done

echo "finished."
