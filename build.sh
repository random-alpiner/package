#!/bin/sh

set -e -x

repo_get() {
    if [[ -e "$repo_dir/.git" ]] ; then
        cd "$repo_dir"
        git reset --hard
        git clean --force
        git pull
    else
        rm -r -f "$repo_dir"
        git clone "$repo_url" "$repo_dir"
    fi
}

repo_put() {
    cd "$repo_dir"
    git add --all  :/
    git status 
    local message=$(git status --short)
    git commit --message "$message"
    git push
}

repo_zero() {
    cd "$repo_dir"
    local pointer=$(git commit-tree HEAD^{tree} -m "current")
    git reset $pointer
    git push --force
}

fetch_deps() {
    local deps_list=$(source "$project/APKBUILD" && echo $makedepends)
    sudo apk add $deps_list
}

copy_keys() {
    local source="$HOME/.abuild"
    local target="$repo_dir/keys"
    mkdir -p "$target"
    cp -f "$source"/*.pub "$target"
}

make_tags() {
    local pkgname=$(source "$project/APKBUILD" && echo $pkgname)
    local pkgver=$(source "$project/APKBUILD" && echo $pkgver)
    local artifact="${pkgname}-${pkgver}"
    cd "$project"
    git tag -a -f -m "$artifact" "$artifact"
}

build_apk() {
    cd "$project"
    abuild checksum
    abuild
}

###

readonly location=$(cd $(dirname $0) && pwd)
readonly project="$location/$1"
readonly repo_url="git@github.com:random-alpiner/repository.git"
readonly repo_dir="$HOME/repository"

repo_get
fetch_deps
make_tags
build_apk
copy_keys
repo_put
repo_zero
