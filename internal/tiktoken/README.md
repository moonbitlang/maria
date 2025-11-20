# Tiktoken

`openai/tiktoken` encode has two phases processing.

1. convert text to pieces via fancy-regex engine.
2. convert pieces to tokens via BPE algorithm.


## Check phase 1 consistency

```bash
cd ./internal/tiktoken/tiktoken_lexer_rs/
cargo run
```