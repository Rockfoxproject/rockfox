#!/usr/bin/env bash
# One-time setup: create the key pair that signs Rockfox updates.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
[[ -d $root/zen ]] || ROCKFOX_REPO=${ROCKFOX_REPO:?Set ROCKFOX_REPO to owner/name} "$root/scripts/prepare.sh"

cd "$root/zen"
bash scripts/mar_sign.sh -g
mkdir -p "$root/signing"
cp build/signing/public_key.der "$root/signing/public_key.der"

echo "Commit signing/public_key.der."
echo "Add the two files in zen/build/signing/env/ as repository secrets with the same names."
echo "Keep zen/build/signing/private_key.pem somewhere safe and never commit it."
