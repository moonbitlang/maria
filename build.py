import subprocess
from pathlib import Path
import argparse

vendor = Path("vendor").resolve()

parser = argparse.ArgumentParser()
parser.add_argument(
    "--build",
    action="store_true",
    help="Build artifacts if they are missing or outdated",
)
args = parser.parse_args()

command = [
    "moon",
    "run",
    "build",
    "--",
    "--project",
    Path.cwd().resolve(),
    "--manifest",
    vendor / "manifest.json",
]

if args.build:
    command.append("--build")

subprocess.run(
    command,
    check=True,
    cwd=vendor,
)
