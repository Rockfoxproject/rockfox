#!/usr/bin/env python3
"""Move upstream.json to the newest Zen and LibreWolf releases.

Writes changed=true to $GITHUB_OUTPUT when something moved.
"""
import json
import os
import re
import shutil
import subprocess
import tempfile
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PINS = ROOT / "upstream.json"
LIBREWOLF_REPO = "https://codeberg.org/librewolf/source.git"


def output(cmd):
    return subprocess.run(cmd, check=True, capture_output=True, text=True).stdout.strip()


def latest_zen(repo):
    return output(["gh", "api", f"repos/{repo}/releases/latest", "--jq", ".tag_name"])


def firefox_version(repo, tag):
    url = f"https://raw.githubusercontent.com/{repo}/{tag}/surfer.json"
    with urllib.request.urlopen(url) as response:
        return json.load(response)["version"]["version"]


def latest_librewolf(max_major):
    refs = output(["git", "ls-remote", "--tags", "--refs", "--sort=-v:refname", LIBREWOLF_REPO])
    for line in refs.splitlines():
        tag = line.split("refs/tags/")[1]
        if re.fullmatch(r"\d+(\.\d+)+-\d+", tag) and int(tag.split(".")[0]) <= max_major:
            return tag
    raise LookupError("no LibreWolf release found")


def vendor_librewolf(tag):
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(
            ["git", "clone", "--quiet", "--depth", "1", "--branch", tag,
             "--recurse-submodules", "--shallow-submodules", LIBREWOLF_REPO, tmp],
            check=True,
        )
        source = Path(tmp)
        config = source / "settings" / "librewolf.cfg"
        if not config.is_file():
            raise FileNotFoundError(config)
        copies = [(config, ROOT / "vendor/librewolf/librewolf.cfg")]
        for line in (ROOT / "patches/firefox/series").read_text().splitlines():
            if not line.strip() or line.startswith("#"):
                continue
            name = line.split()[0]
            found = next((source / "patches").rglob(name), None)
            if found is None:
                print(f"::warning::LibreWolf {tag} no longer ships {name}, keeping the old copy")
            else:
                copies.append((found, ROOT / "patches/firefox" / name))
        for src, dst in copies:
            shutil.copy(src, dst)


def refresh_librewolf(current, max_major):
    try:
        tag = latest_librewolf(max_major)
        if tag != current:
            vendor_librewolf(tag)
        return tag
    except (subprocess.CalledProcessError, LookupError, OSError) as error:
        print(f"::warning::Keeping LibreWolf {current}: {error}")
        return current


def main():
    pins = json.loads(PINS.read_text())
    repo = pins["zen"]["repo"]
    zen_tag = latest_zen(repo)
    firefox = firefox_version(repo, zen_tag)
    librewolf = refresh_librewolf(pins["librewolf"], int(firefox.split(".")[0]))

    zen_moved = zen_tag != pins["zen"]["tag"]
    librewolf_moved = librewolf != pins["librewolf"]
    if zen_moved or librewolf_moved:
        pins["zen"]["tag"] = zen_tag
        pins["firefox"] = firefox
        pins["librewolf"] = librewolf
        pins["revision"] = 1 if zen_moved else pins["revision"] + 1
        PINS.write_text(json.dumps(pins, indent=2) + "\n")
    print(f"Zen {zen_tag}, Firefox {firefox}, LibreWolf {librewolf}, moved: {zen_moved or librewolf_moved}")

    if "GITHUB_OUTPUT" in os.environ:
        with open(os.environ["GITHUB_OUTPUT"], "a") as out:
            out.write(f"changed={'true' if zen_moved or librewolf_moved else 'false'}\n")


if __name__ == "__main__":
    main()
