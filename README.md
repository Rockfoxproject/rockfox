# Rockfox

Rockfox is a Linux browser built from [Zen Browser](https://github.com/zen-browser/desktop) with the privacy hardening of [LibreWolf](https://librewolf.net) added on top. The idea is Zen's design without Zen's phoning home, and a hardened browser that is still pleasant to use every day.

> **Status: early pre-release.** The first build compiles and is signed, but Rockfox has had no independent security review and several things are not tested yet (see [Not tested yet](#not-tested-yet)). Do not rely on it where your safety depends on it.

## What it is

- A soft fork. This repository holds a small set of patches, a preference layer and the build scripts, not Zen's source. A build clones Zen at a pinned tag, applies everything and compiles it.
- Linux x86_64 only.
- Built by GitHub Actions from this repository, and the workflows are public. Each release says which Zen, Firefox and LibreWolf versions it is based on; they are pinned in [`upstream.json`](upstream.json).

## What changes compared to Zen

- The mod store and Share are switched off.
- Donation links and prompts are removed.
- Updates come from this repository's releases and are signed with the project's own key. Zen's update server and key are not used.
- The build uses the same hardening flags as LibreWolf, and the default browser agent and `pingsender` (a telemetry helper) are not built.
- Telemetry and data reporting are also compiled out, with a LibreWolf patch, on top of being switched off in the preferences.
- DRM (encrypted media) is off by default.
- Syncing Spaces is on by default. It only does anything if you sign in to a Firefox account.

## What comes from LibreWolf

- 340 of LibreWolf's preferences are applied. Another 75 are skipped because Zen or Rockfox already sets them, or because they only make sense for LibreWolf's own packaging. Among the values in effect:
  - strict content blocking;
  - Safe Browsing off;
  - DNS over HTTPS off;
  - no captive portal or connectivity checks;
  - no search engine or region updates;
  - the OpenH264 and Widevine plug-ins off, and their update checks;
  - no link prefetching or speculative connections;
  - location lookups go to [BeaconDB](https://beacondb.net), not to Google.
- Six LibreWolf patches to Firefox's source, in [`patches/firefox`](patches/firefox): telemetry compiled out, `pingsender` removed, Remote Settings fetches restricted, the OpenAI backend removed, the alt-svc cache cleared at the end of a session, and Widevine updates allowed once you enable it from its activation popup.

## Where Rockfox differs from LibreWolf

These are choices for daily use, set in [`overrides.yaml`](overlay/prefs/rockfox/overrides.yaml).

- Resist Fingerprinting is off and Firefox's lighter fingerprinting protection is on. Full Resist Fingerprinting forces a light theme, UTC time and a fixed window size, and breaks many sites. The price is that your browser looks less uniform than a default LibreWolf.
- WebGL is enabled.
- History, cookies and sessions are kept between restarts. The built-in Fire button, Firefox's "delete all data", is enabled for wiping everything on demand.
- The password manager is on.
- Firefox accounts are on, but only Spaces are synced. Bookmarks, history, passwords, tabs, add-ons, addresses, cards and settings are not.

## Trade-offs

- With Safe Browsing off, you get no warning for known phishing or malware sites. That keeps URL checks away from Google, and it also removes a safety net.
- If you sign in to sync Spaces, your browser talks to Mozilla's account servers. Spaces sync is experimental in Zen.
- Anything inherited from Zen or Firefox that is not listed here is unchanged, and it has not all been reviewed.

## Not tested yet

- A measured list of the network requests a fresh profile makes. Until there is one, do not assume there are none.
- Automatic updates from one release to the next.
- Playing DRM-protected video such as Netflix.
- Spaces sync.

Also missing: importing a profile from Zen or Firefox, a bundled ad blocker such as uBlock Origin, and aarch64. The build is made without profile-guided optimisation, and some interface strings may still say "Zen".

## Install

There is no release yet. When there is one, download the `.tar.xz` from [Releases](https://github.com/Rockfoxproject/rockfox/releases), extract it and run `rockfox`. A Flatpak is planned.

## Building and contributing

- [`docs/maintaining.md`](docs/maintaining.md) explains how a build works, the signing key and how to run your own.
- Report a security problem as described in [`SECURITY.md`](SECURITY.md), not in a public issue.
- Other bugs and questions go in the [issues](https://github.com/Rockfoxproject/rockfox/issues).

## Credits and licence

Rockfox stands on the work of [Zen Browser](https://github.com/zen-browser/desktop), [LibreWolf](https://librewolf.net) and Mozilla's Firefox. The six patches in `patches/firefox` and `vendor/librewolf/librewolf.cfg` come from LibreWolf.

Rockfox is an independent project. It is not affiliated with or endorsed by Zen Browser, LibreWolf or Mozilla. Firefox is a trademark of the Mozilla Foundation.

Mozilla Public License 2.0, the same as Zen and Firefox. See [`LICENSE`](LICENSE).
