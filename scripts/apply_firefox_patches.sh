#!/usr/bin/env bash
# Apply the LibreWolf patches listed in patches/firefox/series to the Firefox tree.
set -uo pipefail

engine=$(cd "${1:?usage: apply_firefox_patches.sh <engine dir>}" && pwd)
dir=$(cd "$(dirname "$0")/../patches/firefox" && pwd)
status=0

# Cargo checks every file of a vendored crate against its .cargo-checksum.json
refresh_checksums() {
  local file crate manifest
  while read -r file; do
    crate=${file#third_party/rust/}
    crate=${crate%%/*}
    manifest=$engine/third_party/rust/$crate/.cargo-checksum.json
    jq -c --arg path "${file#third_party/rust/$crate/}" \
      --arg sum "$(sha256sum "$engine/$file" | cut -d' ' -f1)" \
      '.files[$path] = $sum' "$manifest" > "$manifest.new" || return 1
    mv "$manifest.new" "$manifest"
  done < <(grep -oP '^\+\+\+ b/\Kthird_party/rust/[^\t ]+' "$1")
}

while read -r name mode; do
  [[ -z $name || $name == \#* ]] && continue
  if patch -d "$engine" -p1 --fuzz=0 --dry-run -s < "$dir/$name" > /dev/null 2>&1; then
    patch -d "$engine" -p1 --fuzz=0 -s < "$dir/$name"
    refresh_checksums "$dir/$name" || { echo "FAILED  $name (cargo checksums)" >&2; exit 1; }
    case $name in
      disable-data-reporting-at-compile-time.patch)
        # Every Glean ping has to follow the data reporting setting
        find "$engine" -path "$engine/.git" -prune -o -type f -name '*.yaml' \
          -exec sed -i 's/follows_collection_enabled: false/follows_collection_enabled: true/' {} +
        ;;
    esac
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
