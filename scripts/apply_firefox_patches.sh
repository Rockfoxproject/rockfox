#!/usr/bin/env bash
# Apply the LibreWolf patches listed in patches/firefox/series to the Firefox tree.
set -uo pipefail

engine=$(cd "${1:?usage: apply_firefox_patches.sh <engine dir>}" && pwd)
dir=$(cd "$(dirname "$0")/../patches/firefox" && pwd)
status=0

while read -r name mode; do
  [[ -z $name || $name == \#* ]] && continue
  if patch -d "$engine" -p1 --fuzz=0 --dry-run -s < "$dir/$name" > /dev/null 2>&1; then
    patch -d "$engine" -p1 --fuzz=0 -s < "$dir/$name"
    echo "applied $name"
  elif [[ $mode == required ]]; then
    echo "FAILED  $name (required)" >&2
    exit 1
  else
    echo "skipped $name (optional)" >&2
    status=2
  fi
done < "$dir/series"
exit $status
