#!/usr/bin/env python3

"""Copy the built sdk.exe into the Python package for distribution."""

from __future__ import annotations

import shutil
import stat
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCE = REPO_ROOT / "target/native/release/build/sdk/sdk.exe"
DESTINATION = REPO_ROOT / "sdk/python/src/maria/bin/sdk.exe"


def _ensure_executable_bits(path: Path) -> None:
    mode = path.stat().st_mode
    path.chmod(mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def main() -> int:
    if not SOURCE.exists():
        print(f"error: missing executable at {SOURCE}", file=sys.stderr)
        return 1
    DESTINATION.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(SOURCE, DESTINATION)
    _ensure_executable_bits(DESTINATION)
    print(f"Bundled {SOURCE} -> {DESTINATION}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
