import urllib
import urllib.request
from pathlib import Path
import tarfile
import subprocess
import tempfile
import platform
import os
import sys
import json
import argparse
import shutil


def download(url: str, destination: str):
    urllib.request.urlretrieve(url, destination)


def extract(tar_path: str, extract_path: str):
    with tarfile.open(tar_path, "r:gz") as tar:
        tar.extractall(path=extract_path)


VENDOR = Path("vendor")


def build_readline(src: Path):
    subprocess.run(
        ["./configure", f"--prefix={VENDOR.resolve()}"],
        check=True,
        cwd=src,
    )
    subprocess.run(
        ["make"],
        check=True,
        cwd=src,
    )
    subprocess.run(
        ["make", "install"],
        check=True,
        cwd=src,
    )


def is_readline_built():
    if platform.system() == "Windows":
        lib_path = VENDOR / "lib" / "libedit.lib"
    elif platform.system() == "Darwin":
        lib_path = VENDOR / "lib" / "libedit.dylib"
    elif platform.system() == "Linux":
        lib_path = VENDOR / "lib64" / "libedit.so"
    else:
        raise NotImplementedError(f"Unsupported platform: {platform.system()}")
    return lib_path.exists()


def main():
    parser = argparse.ArgumentParser(description="Build OpenSSL for MoonBit")
    parser.add_argument(
        "--manual",
        action="store_true",
        help="Run the build script manually without reading from stdin",
    )
    args = parser.parse_args()
    env = os.environ.copy()
    if args.manual is False:
        """Simple cat that reads from stdin and saves content to build.input"""
        text = sys.stdin.read()
        data = json.loads(text)
        env = data
    tar_url = "https://thrysoee.dk/editline/libedit-20250104-3.1.tar.gz"
    tar = VENDOR / "src" / "libedit-20250104-3.1.tar.gz"
    dst = VENDOR / "src"
    if not is_readline_built():
        if not dst.exists():
            dst.mkdir(parents=True, exist_ok=True)
        if not tar.exists():
            download(tar_url, tar)
        shutil.rmtree(dst / "libedit-20250104-3.1", ignore_errors=True)
        extract(tar, dst)
        build_readline(dst / "libedit-20250104-3.1")
    cc = None
    if "CC" in env:
        cc = env["CC"]
    else:
        if platform.system() == "Windows":
            cc = "cl"
        elif platform.system() == "Darwin":
            cc = "clang"
        else:
            cc = "gcc"
    cc_flags = []
    include_directory = VENDOR / "include"
    if platform.system() == "Windows":
        cc_flags.append(f"/I{include_directory}")
    else:
        cc_flags.append(f"-I{include_directory}")
    link_flags = []
    link_libs = []
    link_search_paths = []
    if platform.system() == "Windows":
        link_libs.append(str((VENDOR / "lib").resolve() / "libedit"))
    elif platform.system() == "Darwin":
        link_libs.append("edit")
        link_libs.append("ncurses")
        link_search_paths.append(str((VENDOR / "lib").resolve()))
    elif platform.system() == "Linux":
        link_libs.append("edit")
        link_libs.append("ncurses")
        link_search_paths.append(str((VENDOR / "lib64").resolve()))
    else:
        raise NotImplementedError(f"Unsupported platform: {platform.system()}")
    output = {
        "vars": {
            "CC": cc,
            "CC_FLAGS": " ".join(cc_flags),
        },
        "link_configs": [
            {
                "package": "moonbitlang/maria/readline",
                "link_flags": " ".join(link_flags),
                "link_libs": link_libs,
                "link_search_paths": link_search_paths,
            }
        ],
    }
    sys.stdout.write(json.dumps(output))
    sys.stdout.flush()


if __name__ == "__main__":
    main()
