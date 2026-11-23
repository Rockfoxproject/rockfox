# Rockfox

**LibreWolf's privacy with Zen's design.**

Rockfox is a Linux browser that puts LibreWolf's privacy hardening inside Zen Browser's beautiful, minimal interface. Vertical tabs, Spaces and split view on the outside, a hardened, telemetry-free build on the inside.

> Early pre-release · Linux x86_64 · see [Good to know](#good-to-know) for what is not tested yet

## Why you'll like it

- **Zen's design.** Vertical tabs, Spaces, split view, Glance and a clean, minimal look.
- **LibreWolf's privacy.** 340 privacy and hardening settings applied, plus 6 patches to Firefox's own source code.
- **Telemetry off at the source.** It is turned off when the browser is compiled, not just in the settings.
- **Tracking blocked.** Strict content blocking and fingerprinting protection, with no prefetching or speculative connections behind your back.
- **Made for every day.** WebGL is on, the password manager works, your tabs and logins survive a restart, and the Fire button wipes everything in one click when you want a clean slate.
- **Updates you can trust.** They come only from this repository's releases and are signed with the project's own key.
- **Built in the open.** Every build is made by public GitHub Actions workflows from the code in this repository.

## By the numbers

| | |
| --- | --- |
| **340** | LibreWolf privacy and hardening settings applied |
| **13** | patches applied: 6 from LibreWolf to Firefox's source, 7 of our own on top of Zen |

## Privacy, in practice

- Strict tracking and content blocking out of the box.
- No Safe Browsing lookups, so the sites you visit are not checked against Google's lists.
- No captive portal or connectivity checks, and no search engine or region updates.
- No link prefetching or speculative connections.
- Location lookups go to [BeaconDB](https://beacondb.net), not to Google.
- OpenH264 and Widevine are off until you want them.
- A lighter fingerprinting protection that keeps websites working.

## Install

There is no release yet. When there is one, download the `.tar.xz` from [Releases](https://github.com/Rockfoxproject/rockfox/releases), extract it and run `rockfox`. A Flatpak is planned.

## Good to know

- Rockfox is an early pre-release and has had no independent security review.
- Safe Browsing is off, as in LibreWolf. That keeps your browsing away from Google, and it also means no warning for known phishing and malware sites.
- Syncing Spaces is the only sync. It uses a Firefox account, so your browser talks to Mozilla's servers if you sign in.
- Not tested yet: a measured list of the network requests a fresh profile makes, automatic updates from one release to the next, DRM video such as Netflix, and Spaces sync.
- Not there yet: importing a profile from Zen or Firefox, a bundled ad blocker and aarch64. Some interface text may still say "Zen".

## Build it, report a problem

- [`docs/maintaining.md`](docs/maintaining.md) explains how a build works and how to run your own.
- Report a security problem as described in [`SECURITY.md`](SECURITY.md), not in a public issue.
- Other bugs and questions go in the [issues](https://github.com/Rockfoxproject/rockfox/issues).

## Credits and licence

Rockfox exists thanks to the [Zen Browser](https://github.com/zen-browser/desktop) and [LibreWolf](https://librewolf.net) teams and to Mozilla's Firefox. The six Firefox patches and the settings list in `vendor/librewolf` come from LibreWolf.

Rockfox is an independent project. It is not affiliated with or endorsed by Zen Browser, LibreWolf or Mozilla. Firefox is a trademark of the Mozilla Foundation.

Mozilla Public License 2.0, the same as Zen and Firefox. See [`LICENSE`](LICENSE).
