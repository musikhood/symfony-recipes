#!/usr/bin/env python3
"""Fails when a repo file contains company domains or internal product / repo names.

The recipes are public (fetched by any Flex consumer): only generic examples
(https://auth.example.com). Same patterns as `scripts/leak-check.mjs` in the
auth-client repo and `tests/Meta/NoInternalNamesTest.php` in auth-client-bundle;
written so they do not match their own source.

Usage: scripts/leak-check.py [files...]   (default: every file tracked by git
plus untracked, not ignored ones — i.e. what a commit could contain)
"""
import re
import subprocess
import sys
from pathlib import Path

PATTERNS = [
    re.compile(r"vitkac\.com", re.I),
    re.compile(r"vitkac\.sni\.pl", re.I),
    re.compile(r"\bsni\.pl\b", re.I),
    re.compile(r"\bmusikhood\.(?!io\b|com\b)\w+", re.I),
    re.compile(r"\beditor[_-]v3", re.I),
    re.compile(r"\bai[-_ ]panel\b", re.I),
    re.compile(r"\bpim[_]frontend\b", re.I),
    re.compile(r"\bauth[-]panel", re.I),
    re.compile(r"\bAPI\sCore\b"),
]
SKIP_SUFFIXES = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".ico", ".zip", ".gz", ".tgz"}


def repo_files() -> list[str]:
    out = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard"],
        check=True, capture_output=True, text=True,
    ).stdout
    return [line for line in out.splitlines() if line]


def main(argv: list[str]) -> int:
    files = argv or repo_files()
    leaks = []
    for name in files:
        path = Path(name)
        if path.suffix.lower() in SKIP_SUFFIXES or not path.is_file():
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for pattern in PATTERNS:
            match = pattern.search(text)
            if match:
                leaks.append(f"{name}: {match.group(0)}")
    for leak in leaks:
        print(f"leak-check: {leak}", file=sys.stderr)
    if leaks:
        print("\nUsuń wpisy lub zastąp je generycznymi (np. https://auth.example.com).", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
