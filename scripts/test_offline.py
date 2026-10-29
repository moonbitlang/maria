#!/usr/bin/env python3
"""Run deterministic native tests without provider credentials or live-model cases."""
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
# These files contain live model calls, including unskipped documentation examples.
# They remain covered by the existing credentialed integration job.
LIVE_MODEL_FILES = {
    'README.mbt.md', 'maria_test.mbt',
    'agent/README.mbt.md', 'agent/agent_test.mbt', 'agent/agent_wbtest.mbt',
    'cmd/server/server_test.mbt', 'cmd/daemon/daemon_test.mbt',
    'tools/todo/agent_todo_test.mbt',
    'tools/replace_in_file/agentic_integration_test.mbt',
    'tools/search_files/agentic_integration_test.mbt',
}
paths = []
for path in sorted(ROOT.rglob('*')):
    relative = path.relative_to(ROOT)
    if any(part in {'.git', '.mooncakes', '_build', '__trajectories__', 'system'} for part in relative.parts):
        continue
    if str(relative) in LIVE_MODEL_FILES:
        continue
    if path.name.endswith(('_test.mbt', '_wbtest.mbt', '.mbt.md')):
        paths.append(str(relative))
env = dict(os.environ)
for key in ('OPENAI_API_KEY', 'OPENROUTER_API_KEY', 'DEEPSEEK_API_KEY', 'MOONSHOT_API_KEY', 'DASHSCOPE_API_KEY'):
    env.pop(key, None)
# Model-loader unit tests serialize and reload this value; it is not a credential.
env['OPENAI_API_KEY'] = 'maria-offline-fixture'
print(f'Running {len(paths)} test files; live model files are covered separately.', flush=True)
subprocess.run(['moon', 'test', '--target', 'native', *sys.argv[1:], *paths], cwd=ROOT, env=env, check=True)
