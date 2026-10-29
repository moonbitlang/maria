#!/usr/bin/env python3
"""Verify the built-in native abort replacement retains message and source stack."""
import pathlib
import resource
import subprocess
import tempfile

with tempfile.TemporaryDirectory(prefix='maria-abort-') as directory:
    root = pathlib.Path(directory)
    (root / 'moon.mod').write_text('name = "maria-audit/abort-probe"\npreferred_target = "native"\n')
    (root / 'moon.pkg').write_text('options(is_main: true)\n')
    (root / 'main.mbt').write_text('fn crash() -> Unit { abort("maria abort regression marker") }\nfn main { crash() }\n')
    subprocess.run(['moon', 'build', '--target', 'native'], cwd=root, check=True)
    executable = root / '_build/native/debug/build/abort-probe.exe'
    # Avoid a core dump for this intentionally aborting child.
    def no_core():
        resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    result = subprocess.run([str(executable)], cwd=root, capture_output=True, text=True, preexec_fn=no_core)
    assert result.returncode != 0, result
    assert 'maria abort regression marker' in result.stderr, result.stderr
    assert 'crash' in result.stderr and 'main.mbt' in result.stderr, result.stderr
    print('Native abort message and source-level backtrace verified.')
