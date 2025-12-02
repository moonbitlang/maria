"""Embed markdown files into MoonBit string constants.

This script reads markdown files and generates MoonBit source files containing
the markdown content as multi-line string constants using the #| syntax.

Usage:
    python scripts/embed.py

The script should be run from the project root directory. It will:
1. Initialize/update git submodules
2. For each manifest entry, read the source markdown file and generate a 
   corresponding .mbt file with the content embedded as a string constant.

To add a new embedded file:
1. Create your markdown file (e.g., tools/my_tool/prompt.md)
2. Add a new Manifest entry to the `manifests` list below
3. Run this script to generate the .mbt file
"""

from pathlib import Path
from dataclasses import dataclass
import subprocess


@dataclass
class Manifest:
    source: Path
    destination: Path
    name: str
    is_pub: bool
    is_const: bool

    def embed(self) -> None:
        text = self.source.read_text()
        lines = ["///|"]
        if self.is_pub:
            if self.is_const:
                lines.append(f"pub const {self.name} : String =")
            else:
                lines.append(f"pub let {self.name} : String =")
        else:
            if self.is_const:
                lines.append(f"const {self.name} : String =")
            else:
                lines.append(f"let {self.name} : String =")
        for line in text.splitlines():
            lines.append(f"  #|{line}")
        lines.append("")
        self.destination.write_text("\n".join(lines))
        print(f"EMBED {self.source} -> {self.destination}")


manifests = [
    Manifest(
        source=Path("prompt/system-prompt/Agents.mbt.md"),
        destination=Path("prompt/moonbit.mbt"),
        name="moonbit",
        is_pub=True,
        is_const=False,
    ),
    Manifest(
        source=Path("tools/meta_write_to_file/syntax_error.md"),
        destination=Path("tools/meta_write_to_file/prompt.mbt"),
        name="syntax_error_expert_prompt",
        is_pub=False,
        is_const=False,
    ),
    Manifest(
        source=Path("tools/todo/prompt.md"),
        destination=Path("tools/todo/prompt.mbt"),
        name="prompt",
        is_pub=True,
        is_const=False,
    ),
]


def main():
    subprocess.run(["git", "submodule", "update", "--init", "--recursive"], check=True)
    for manifest in manifests:
        manifest.embed()


if __name__ == "__main__":
    main()
