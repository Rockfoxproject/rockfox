#!/usr/bin/env python3
"""Turn LibreWolf's librewolf.cfg into a prefs YAML file for the Zen tree.

usage: lw_prefs.py librewolf.cfg zen/prefs overrides.yaml > librewolf.yaml

A pref is left out when Zen or Rockfox already defines it, or when it only
makes sense for LibreWolf's own packaging (updater, branding, toolbar layout).
"""
import json
import re
import sys
from pathlib import Path

CALL = re.compile(
    r'^(defaultPref|pref|lockPref)\(\s*"([^"]+)"\s*,\s*'
    r'(true|false|-?\d+|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|`[^`]*`)\s*\)\s*;',
    re.M,
)
STARTS_PREF = re.compile(r"^(defaultPref|pref|lockPref)\(", re.M)
LIBREWOLF_ONLY = re.compile(
    r"^(app\.(update|releaseNotesURL|support)|general\.config\.|"
    r"browser\.uiCustomization\.|browser\.toolbars\.)"
)
YAML_NAME = re.compile(r"^- name: (\S+)", re.M)


def defined_names(*paths):
    names = set()
    for path in paths:
        files = Path(path).rglob("*.yaml") if Path(path).is_dir() else [Path(path)]
        for f in files:
            names.update(YAML_NAME.findall(f.read_text()))
    return names


def literal(raw):
    if raw in ("true", "false"):
        return raw == "true"
    if raw[0] == '"':
        return json.loads(raw)
    if raw[0] in "'`":
        return raw[1:-1].replace("\\'", "'")
    return int(raw)


def main(cfg, zen_prefs, overrides):
    text = Path(cfg).read_text()
    taken = defined_names(zen_prefs, overrides)
    prefs, skipped = {}, 0
    for match in CALL.finditer(text):
        kind, name, raw = match.groups()
        if name in taken or LIBREWOLF_ONLY.match(name):
            skipped += 1
            continue
        prefs[name] = (literal(raw), kind == "lockPref")

    parsed = {m.start() for m in CALL.finditer(text)}
    unparsed = [
        text.count("\n", 0, m.start()) + 1
        for m in STARTS_PREF.finditer(text)
        if m.start() not in parsed
    ]

    print("# Generated from LibreWolf's librewolf.cfg by scripts/lw_prefs.py\n")
    for name, (value, locked) in prefs.items():
        print(f"- name: {name}\n  value: {json.dumps(value)}")
        if locked:
            print("  locked: true")
        print()
    print(
        f"{len(prefs)} prefs written, {skipped} left out, "
        f"{len(unparsed)} unparsed: {unparsed}",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main(*sys.argv[1:4])
