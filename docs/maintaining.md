# Maintaining Rockfox

How the build works and how to run it. For what the browser is and does, see the [README](../README.md).

## How a build works

This repository does not contain Zen's source. `scripts/prepare.sh` clones Zen at the tag pinned in `upstream.json`, applies `patches/zen/`, fills in the identity strings from `replacements.tsv`, copies `overlay/` over the tree, turns LibreWolf's `librewolf.cfg` into Zen-style preferences and installs the update signing certificate. After Zen has imported Firefox's source, `scripts/apply_firefox_patches.sh` applies the LibreWolf patches. Then Zen's own build and packaging scripts run.

| Path | What it is |
| --- | --- |
| `upstream.json` | Pinned Zen tag, Firefox and LibreWolf versions, Rockfox revision |
| `patches/zen/` | Patches applied to Zen's source, plus `replacements.tsv` for identity strings |
| `patches/firefox/` | Patches taken from LibreWolf, applied to Firefox after Zen's import |
| `overlay/` | Files copied over Zen's tree: preference overrides and branding |
| `vendor/librewolf/` | LibreWolf's `librewolf.cfg`, converted into Zen-style preferences at build time |
| `signing/public_key.der` | Public certificate of the update signing key, built into the updater |
| `scripts/` | `prepare.sh`, `apply_firefox_patches.sh`, `lw_prefs.py`, `branding.sh`, `track_upstream.py`, `gen_signing_key.sh` |
| `.github/workflows/` | `build.yml` builds and publishes, `track-upstream.yml` follows upstream |

Preferences are layered. Zen's own value wins when both define a name. LibreWolf fills the gaps. `overlay/prefs/rockfox/overrides.yaml` wins over both.

All six LibreWolf patches in `patches/firefox/series` are optional. One that stops applying is skipped and listed in the release notes instead of failing the build. After each patch the script also updates the checksums of any vendored Rust crate the patch touched, because cargo rejects the crate otherwise, and makes every Glean ping follow the data reporting setting.

Versions look like `1.24.3b-rf1`: the Zen tag plus the Rockfox revision, which restarts at 1 with every new Zen tag.

## Running a build

```
gh workflow run build.yml
```

Add `-f publish=true` to publish a release when the build succeeds. A build takes about 1 h 50 min on a standard GitHub runner, well inside the six hour job limit. If that ever stops being true, set the repository variable `ROCKFOX_RUNNER` to the label of a larger runner.

The build saves its results as three artifacts:

| Artifact | Contents | Kept |
| --- | --- | --- |
| `rockfox-linux-x86_64` | `rockfox.linux-x86_64.tar.xz`, the browser | 14 days |
| `rockfox-update-linux-x86_64` | the signed `linux.mar` and `update-linux-x86_64.xml` | 14 days |
| `rockfox-update-unsigned` | the update before signing | 5 days |

The browser is saved before the signing step, so a signing failure does not lose it. To download it:

```
gh run download RUN_ID -R Rockfoxproject/rockfoxbrowser -n rockfox-linux-x86_64 -D ~/rockfox-build
```

`gh run list` shows the run ID. Publishing only works when the signing secrets are set, and the release tag is the version string, for example `1.24.3b-rf1`.

## Signing

- `signing/public_key.der` is committed and is built into the updater. The private key and its certificate are stored as the repository secrets `ZEN_SIGNING_PRIVATE_KEY_PEM_BASE64` and `ZEN_SIGNING_CERT_PEM_BASE64`.
- Before the compile starts, the workflow checks that the two secrets belong together and match `signing/public_key.der`, so a wrong key fails in minutes and not at the end of the build.
- The NSS database that holds the key during signing has an empty password on purpose. `signmar` asks for a password on standard input when the database has one, and a workflow step has nobody to type it.
- Without the secrets, a build makes a throwaway key. Such a build works for testing, cannot be published and cannot update.

To create a key, run `ROCKFOX_REPO=Rockfoxproject/rockfoxbrowser ./scripts/gen_signing_key.sh` on a Linux machine with `git`, `jq`, `python3` and `openssl`. Commit `signing/public_key.der`, then add the two files in `zen/build/signing/env/` as secrets with the same names, for example `gh secret set ZEN_SIGNING_CERT_PEM_BASE64 < zen/build/signing/env/ZEN_SIGNING_CERT_PEM_BASE64`.

Keep a copy of `zen/build/signing/private_key.pem` and `cert.pem` outside your computer and never commit them. If the private key is lost, installed copies can no longer be updated automatically. There is no key rotation procedure yet.

## Following upstream

`track-upstream.yml` asks GitHub for the latest Zen release and Codeberg for the latest LibreWolf tag every six hours. On a change it refreshes the vendored files, runs `prepare.sh` as a dry check, commits the new pin and starts a build with publishing on. If the patches no longer apply it opens an issue and commits nothing. A failure to reach LibreWolf never blocks a Zen update.

It is disabled for now. Enable it once a release has been tested:

```
gh workflow enable track-upstream.yml -R Rockfoxproject/rockfoxbrowser
```

GitHub pauses scheduled workflows after 60 days without activity in the repository. Enable it again from the Actions tab if that happens.

## Renaming the repository

The repository name is built into the browser: the update address and the links in the about page. The repository was renamed from `rockfox` to `rockfoxbrowser` before the first release. Do not create another repository called `rockfox` in the same account, or the old links stop redirecting. A rename needs a new build, because the name is compiled in.

## Building locally

```
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
ROCKFOX_REPO=Rockfoxproject/rockfoxbrowser ./scripts/prepare.sh
cd zen
npm ci
npm run surfer -- ci --brand release --display-version 1.24.3b-rf1
npm run download
npm run import
cd .. && scripts/apply_firefox_patches.sh zen/engine && cd zen
sh scripts/download-language-packs.sh
npm run build
npm run package
```

The git identity is needed because the download step makes a commit. `.github/workflows/build.yml` has the full list of system packages and environment variables.

## Logo

Replace `branding/logo.png` with a square PNG, at least 1024 pixels wide and with a transparent background, and run `scripts/branding.sh`. It needs ImageMagick and regenerates the files in `overlay/configs/branding/release/`. An SVG can be passed as an argument instead, and then it needs `rsvg-convert`.

## Known gaps

- Importing a profile from `~/.zen` is not implemented.
- uBlock Origin is not bundled.
- There is no automated check that a fresh profile makes no unexpected network requests.
- Some interface strings in Zen's locale files may still say "Zen".
- Linux x86_64 only, built without profile-guided optimisation.
- Zen's Windows and macOS assets are still in the tree. They are unused.
