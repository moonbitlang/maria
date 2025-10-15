# Tiktoken

## Check Inconsistencies

Unicode test cases are skipped because they can not be decode back to original
text.

```bash
uv run pytest ./scripts/validate.py -vv
```
