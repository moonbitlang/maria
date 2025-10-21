import tiktoken
import json
from pathlib import Path


def test_consistency():
    tokenizer = tiktoken.get_encoding("cl100k_base")
    splitted_file = Path(__file__).parent.parent / "__snapshot__" / "splitted.json"
    splitted_text = splitted_file.read_text()
    splitted_json = json.loads(splitted_text)
    for key, case in splitted_json.items():
        # Skip over cases where text contains unicode characters
        if any(ord(c) > 127 for c in case["text"]):
            continue
        tokens = tokenizer.encode(case["text"])
        splitteds = []
        for token in tokens:
            splitteds.append(tokenizer.decode([token]))
        assert splitteds == case["splitteds"], f"Failed on case `{key}`"
