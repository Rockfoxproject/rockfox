#!/usr/bin/env bash
# Fetch Zen at the pinned tag and turn it into the Rockfox source tree in ./zen.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

repo=${ROCKFOX_REPO:-${GITHUB_REPOSITORY:-}}
[[ -n $repo ]] || { echo "Set ROCKFOX_REPO to owner/name of this repository." >&2; exit 1; }
# Static update manifest on the latest release; the query swallows the updater's own path.
update_url=${ROCKFOX_UPDATE_URL:-github.com/$repo/releases/latest/download/update-linux-x86_64.xml?}

zen_repo=$(jq -r .zen.repo upstream.json)
zen_tag=$(jq -r .zen.tag upstream.json)

rm -rf zen
git clone --quiet --depth 1 --recurse-submodules --shallow-submodules --branch "$zen_tag" "https://github.com/$zen_repo.git" zen

for patch in patches/zen/*.patch; do
  git -C zen apply "$root/$patch"
done

while IFS=$'\t' read -r file old new; do
  [[ -z $file || $file == \#* ]] && continue
  new=${new//@REPO@/$repo}
  new=${new//@UPDATE_URL@/$update_url}
  OLD=$old NEW=$new python3 - "zen/$file" <<'PY'
import os, sys
path = sys.argv[1]
text = open(path).read()
if os.environ["OLD"] not in text:
    sys.exit(f"{path}: '{os.environ['OLD']}' not found")
open(path, "w").write(text.replace(os.environ["OLD"], os.environ["NEW"]))
PY
done < patches/zen/replacements.tsv

jq --arg repo "$repo" '
  .name = "Rockfox" | .vendor = "Rockfox" | .appId = "rockfox" | .binaryName = "rockfox"
  | .updateHostname = "github.com"
  | .brands.release.brandShorterName = "Rockfox"
  | .brands.release.brandShortName = "Rockfox"
  | .brands.release.brandFullName = "Rockfox"
  | .brands.release.release.github.repo = $repo
  | .brands.twilight.release.github.repo = $repo' zen/surfer.json > zen/surfer.json.new
mv zen/surfer.json.new zen/surfer.json

cp -a overlay/. zen/
python3 scripts/lw_prefs.py vendor/librewolf/librewolf.cfg zen/prefs zen/prefs/rockfox/overrides.yaml \
  > zen/prefs/rockfox/librewolf.yaml

if [[ -f signing/public_key.der ]]; then
  mkdir -p zen/build/signing
  cp signing/public_key.der zen/build/signing/public_key.der
else
  echo "warning: signing/public_key.der is missing, the tree keeps Zen's update key" >&2
fi
