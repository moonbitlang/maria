#!/usr/bin/env python3

"""Copy the built sdk.exe into the Python package for distribution."""

import shutil
from pathlib import Path
import subprocess
import platform


def main():
    target = f"{platform.system().lower()}-{platform.machine().lower()}"
    subprocess.run(["moon", "build", "--target", "native", "--release"], check=True)
    main_exe = (
        Path.cwd() / "target" / "native" / "release" / "build" / "main" / "main.exe"
    )
    sdk_path = Path("sdk")
    shutil.copy(
        main_exe, sdk_path / "python" / "maria" / "bin" / f"{target}.exe"
    )


if __name__ == "__main__":
    main()
