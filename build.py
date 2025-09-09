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


GPG_KEY = """-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.2.4 (Darwin)

mQGiBEEOsGwRBACFa0A1oa71HSZLWxAx0svXzhOZNQZOzqHmSuGOG92jIpQpr8Dp
vgRh40YpAwdcXb8QG1J5yGAKeevNE1zCFaA725vGSdHUyypHouV0xoWwukYO6qly
yX+2BZU+okBUqoWQkoWxiYaCSfzB2Ln7pmdys1fJhcgBKf3VjWCjd2XJTwCgoFJO
wyBFJdugjfwjSoRSwDOIMf0D/iQKqlWhIO1LGpMrGX0il0/x4zj0NAcSwAk7LaPZ
bN4UPjn5pqGEHBlf1+xDDQCkAoZ/VqESGZragl4VqJfxBr29Ag0UDvNbUbXoxQsA
Rdero1M8GiAIRc50hj7HXFoERwenbNDJL86GPLAQOTGOCa4W2o29nFfFjQrsrrYH
zVtyA/9oyKvTeEMJ7NA3VJdWcmn7gOu0FxEmSNhSoV1T4vP21Wf7f5niCCRKQLNy
Uy0wEApQi4tSysdz+AbgAc0b/bHYVzIf2uO2lIEZQNNt+3g2bmXgloWmW5fsm/di
50Gm1l1Na63d3RZ00SeFQos6WEwLUHEB0yp6KXluXLLIZitEJLQaQ2hldCBSYW1l
eSA8Y2hldEBjd3J1LmVkdT6IXgQTEQIAHgUCQQ6wbAIbAwYLCQgHAwIDFQIDAxYC
AQIeAQIXgAAKCRC7WGnwZOp0q87NAJ99FEzFvDdYzqCczXF6KKXi7YN5OACfacDY
soZcnnsy7EjBZL0zwGwb/sG5AQ0EQQ6wbxAEAJCukwDigRDPhAuI+lf+6P64lWan
IFOXIndqhvU13cDbQ/Wt5LwPzm2QTvd7F+fcHOgZ8KOFScbDpjJaRqwIybMTcIN0
B2pBLX/C10W1aY+cUrXZgXUGVISEMmpaP9v02auToo7XXVEHC+XLO9IU7/xaU98F
L69l6/K4xeNSBRM/AAMHA/wNAmRBpcyK0+VggZ5esQaIP/LyolAm2qwcmrd3dZi+
g24s7yjV0EUwvRP7xHRDQFgkAo6++QbuecU/J90lxrVnQwucZmfz9zgWDkT/MpfB
/CNRSKLFjhYq2yHmHWT6vEjw9Ry/hF6Pc0oh1a62USdfaKAiim0nVxxQmPmiRvtC
mYhJBBgRAgAJBQJBDrBvAhsMAAoJELtYafBk6nSr43AAn2ZZFQg8Gs/zUzvXMt7e
vaFqVTzcAJ0cHtKpP1i/4H4R9+OsYeQdxxWxTQ==
=2MjR
-----END PGP PUBLIC KEY BLOCK-----
"""


def gpg_verify(sig_path: Path, tar_path: Path):
    with tempfile.TemporaryDirectory() as tempdir:
        key_path = Path(tempdir) / "gpgkey.asc"
        with open(key_path, "w") as f:
            f.write(GPG_KEY)
        subprocess.run(
            [
                "gpg",
                "--import",
                key_path.resolve(),
            ],
            check=True,
            cwd=tempdir,
        )
        subprocess.run(
            ["gpg", "--verify", sig_path.resolve(), tar_path.resolve()],
            check=True,
            cwd=tempdir,
        )


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
        lib_path = VENDOR / "lib" / "libreadline.lib"
    elif platform.system() == "Darwin":
        lib_path = VENDOR / "lib" / "libreadline.dylib"
    elif platform.system() == "Linux":
        lib_path = VENDOR / "lib64" / "libreadline.so"
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
    tar_url = "ftp://ftp.gnu.org/gnu/readline/readline-8.3.tar.gz"
    sig_url = tar_url + ".sig"
    tar = VENDOR / "src" / "readline-8.3.tar.gz"
    sig = VENDOR / "src" / "readline-8.3.tar.gz.sig"
    dst = VENDOR / "src"
    if not is_readline_built():
        if not dst.exists():
            dst.mkdir(parents=True, exist_ok=True)
        if not tar.exists():
            download(tar_url, tar)
        if not sig.exists():
            download(sig_url, sig)
        gpg_verify(sig, tar)
        shutil.rmtree(dst / "readline-8.3", ignore_errors=True)
        extract(tar, dst)
        build_readline(dst / "readline-8.3")
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
        link_libs.append(str((VENDOR / "lib").resolve() / "libhistory"))
        link_libs.append(str((VENDOR / "lib").resolve() / "libreadline"))
    elif platform.system() == "Darwin":
        link_libs.append("history")
        link_libs.append("readline")
        link_search_paths.append(str((VENDOR / "lib").resolve()))
    elif platform.system() == "Linux":
        link_libs.append("history")
        link_libs.append("readline")
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
