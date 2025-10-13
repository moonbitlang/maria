# `moonbitlang/maria/tiktoken`

Token encoding using tiktoken (OpenAI's tokenizer).

## Overview

This package provides access to tiktoken encodings for tokenizing text according to OpenAI's tokenization schemes, primarily used for GPT models.

## Usage

### Using cl100k_base Encoding

```moonbit
let encoding = @tiktoken.cl100k_base()
let tokens = encoding.encode("Hello, World!")
// Returns array of token IDs
let token_count = tokens.length()
let _ = token_count
```

### Decoding Tokens

```moonbit
let encoding = @tiktoken.cl100k_base()
let tokens = encoding.encode("Hello!")
let text = encoding.decode(tokens)
text // "Hello!"
```

## API Reference

### Types

#### `Encoding`

A tokenization encoding scheme.

**Methods:**
- `encode(text: String) -> Array[Int]`: Encodes text to token IDs
- `decode(tokens: Array[Int]) -> String`: Decodes token IDs to text

### Functions

#### `cl100k_base() -> Encoding raise`

Creates the cl100k_base encoding.

This is the encoding used by:
- GPT-3.5-turbo
- GPT-4
- GPT-4-turbo
- text-embedding-ada-002

## Tokenization

Tokenization breaks text into subword units:

- Common words: single tokens (e.g., "hello" → 1 token)
- Rare words: multiple tokens (e.g., "antidisestablishmentarianism" → multiple tokens)
- Special characters and spaces: often separate tokens
- Numbers: may be split into individual digits

## Notes

- tiktoken is OpenAI's fast tokenizer implementation
- Token counts affect API costs and context limits
- The cl100k_base encoding is the most commonly used
- Encoding is deterministic and consistent
- Used by the `@token` package for counting tokens in messages
