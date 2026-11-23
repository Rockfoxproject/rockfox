# Rockfox

Rockfox is a Linux-only soft fork of [Zen Browser](https://github.com/zen-browser/desktop) with the privacy hardening of [LibreWolf](https://librewolf.net) added on top. The idea is simple: Zen's design without Zen's phoning home, and a hardened browser that is still pleasant to use every day. WebGL works, DRM can be switched on for streaming services, and a Fire button wipes all browsing data in one click.

This repository does not contain Zen's source. It holds a small set of patches, a preference layer and a few scripts. A build clones Zen at a pinned tag, applies everything and compiles the result. When Zen or LibreWolf publish a new release, a scheduled workflow moves the pin, checks that the patches still apply and starts a new build.

## What changes

Compared to Zen:

- The mod store and Share are off. The code paths are neutralised, not just hidden.
- Donation prompts and links are removed.
- Update checks go to this repository's releases, and updates are signed with your own key.
- Hardened compiler flags, no default-browser agent, no pingsender.
- Profile directory is `~/.rockfox`, so it never touches an existing `~/.zen`.

Compared to LibreWolf, to make it usable every day:

- `privacy.resistFingerprinting` is off and Firefox's fingerprinting protection is on. Resist Fingerprinting breaks too many sites, and it forces a UTC clock and a letterboxed window.
- WebGL is enabled.
- DRM stays off until you enable it from the usual prompt. Zen's Linux build already ships with Widevine support.
- History and cookies are not cleared on shutdown. The Fire button does it on demand.
- The password manager is on.
- Sync is allowed, but only for Spaces. Every other sync engine is off. Spaces sync is experimental upstream.

## Layout

| Path | What it is |
| --- | --- |
| `upstream.json` | Pinned Zen tag, Firefox and LibreWolf versions, Rockfox revision |
| `patches/zen/` | Patches applied to Zen's source, plus `replacements.tsv` for identity strings |
| `patches/firefox/` | Patches taken from LibreWolf, applied to Firefox after Zen's import |
| `overlay/` | Files copied over Zen's tree: preference overrides and branding |
| `vendor/librewolf/` | LibreWolf's `librewolf.cfg`, converted into Zen-style preferences at build time |
| `scripts/prepare.sh` | Builds the `zen/` source tree from the pin, the patches and the overlay |
| `scripts/track_upstream.py` | Looks for new Zen and LibreWolf releases and updates the pin |
| `.github/workflows/` | `build.yml` builds and publishes, `track-upstream.yml` runs every six hours |

Preferences are layered. Zen's own value wins when both define a name. LibreWolf fills the gaps. `overlay/prefs/rockfox/overrides.yaml` wins over both.

The LibreWolf patches in `patches/firefox/series` are all optional. One that stops applying is skipped and listed in the release notes instead of failing the build.

## Setting it up

You do this once.

1. Create a public GitHub repository and push this folder to it. The workflows read the repository name themselves.
2. Create the signing key. From a Linux machine with `git`, `jq`, `python3` and `openssl`:

   ```
   ROCKFOX_REPO=owner/name ./scripts/gen_signing_key.sh
   ```

   Commit `signing/public_key.der`. Add the two files in `zen/build/signing/env/` as repository secrets with the same names (`ZEN_SIGNING_CERT_PEM_BASE64` and `ZEN_SIGNING_PRIVATE_KEY_PEM_BASE64`). Keep `zen/build/signing/private_key.pem` somewhere safe and never commit it. If it is lost, installed copies can no longer be updated.
3. In the Actions tab, run Build once by hand with "Publish" ticked. From then on `track-upstream.yml` does the rest.

If a build runs into GitHub's six hour job limit, set the repository variable `ROCKFOX_RUNNER` to the label of a larger runner.

GitHub pauses scheduled workflows after 60 days without repository activity. Re-enable it from the Actions tab if that ever happens.

## Updates

`track-upstream.yml` asks GitHub for the latest Zen release and Codeberg for the latest LibreWolf tag. On a change it refreshes the vendored files, runs `prepare.sh` as a dry check, commits the new pin and starts a build. If the patches no longer apply it opens an issue and commits nothing. A failure to reach LibreWolf never blocks a Zen update.

Versions look like `1.24.3b-rf1`: the Zen tag plus the Rockfox revision, which restarts at 1 with every new Zen tag.

## Building locally

```
ROCKFOX_REPO=owner/name ./scripts/prepare.sh
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

`.github/workflows/build.yml` has the complete list, including system packages and environment variables.

## Logo

Replace `branding/logo.svg` and run `scripts/branding.sh`. It needs `rsvg-convert` or ImageMagick and regenerates the files in `overlay/configs/branding/release/`. The current logo is a placeholder.

## Known gaps

- Nothing here has been through a full build yet. Expect the first CI run to need a fix or two.
- Some interface strings in Zen's locale files still say "Zen".
- Linux x86_64 only. No aarch64, no PGO or LTO.
- Importing a profile from `~/.zen` is not implemented.
- uBlock Origin is not bundled.
- There is no automated check yet that a fresh profile makes no unexpected network requests.
- Zen's Windows and macOS assets are still in the tree. They are unused.

## License

Mozilla Public License 2.0, the same as Zen and Firefox.
