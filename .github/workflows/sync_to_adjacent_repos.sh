#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-02-13 15:36:35 +0000 (Thu, 13 Feb 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

cd "$srcdir"

sync_file(){
    local filename="$1"
    target="../../../$dir/.github/workflows/$filename"
    if [ -f "$target.disabled" ]; then
        target="$target.disabled"
    fi
    if [ -f "$target" ] || [ -n "${NEW:-}" ]; then
        targetdir="${target%/*}"
        mkdir -p -v "$targetdir"
        echo "syncing $filename -> $target"
        perl -p -e "s/(DevOps-)?Bash-tools/$repo/i" "$filename" > "$target"
        if [[ "$repo" =~ nagios-plugins ]]; then
            timeout=240
            perl -pi -e "s/(^\\s*timeout-minutes:).*/\\1 $timeout/" "$target"
            perl -pi -e 's/(^[[:space:]]+make$)/\1 build zookeeper/' "$target"
        fi
    fi
}

sed 's/#.*//; s/:/ /' ../../setup/repos.txt |
grep -v -e bash-tools -e '^[[:space:]]*$' |
while read -r repo dir; do
    if [ -z "$dir" ]; then
        dir="$repo"
    fi
    repo="$(tr '[:upper:]' '[:lower:]' <<< "$repo")"
    if ! [ -d "../../../$dir" ]; then
        echo "WARNING: repo dir $dir not found, skipping..."
        continue
    fi
    if [ $# -gt 0 ]; then
        for filename in "$@"; do
            sync_file "$filename"
        done
    else
        for filename in *.yaml; do
            sync_file "$filename"
        done
    fi
done
