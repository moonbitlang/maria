# `moonbitlang/maria/base64`

Base64 encoding and decoding following RFC 4648.

## Overview

This package provides efficient Base64 encoding and decoding with support for both standard and URL-safe variants, as well as optional padding.

## Usage

### Basic Encoding

```moonbit
///|
test "basic encoding" {
  let data = b"Hello, World!"
  let encoded = @base64.encode(data)
  @json.inspect(encoded, content="SGVsbG8sIFdvcmxkIQ==")
}
```

### Basic Decoding

```moonbit
///|
test "basic decoding" {
  let encoded = "SGVsbG8sIFdvcmxkIQ=="
  let decoded = @base64.decode(encoded)
  @json.inspect(decoded, content=b"Hello, World!")
}
```

### URL-Safe Encoding

```moonbit
///|
test "url safe encoding" {
  let data = b"test\xFF\xFE"
  let encoded = @base64.encode(data, url_safe=true)
  // URL-safe uses '-' and '_' instead of '+' and '/'
  let _ = encoded
}
```

### Streaming Encoding

```moonbit
///|
test "streaming encoding" {
  let encoder = @base64.Encoder::new()
  let builder = StringBuilder::new()
  encoder.encode_to(
    b"Hello",
    fn(ch) { builder.write_char(ch) },
    padding=true
  )
  @json.inspect(builder.to_string(), content="SGVsbG8=")
}
```

## API Reference

### Functions

#### `encode(bytes: BytesView, url_safe?: Bool = false) -> String`

Encodes binary data to Base64 string.

- **Parameters:**
  - `bytes`: The binary data to encode
  - `url_safe`: If `true`, uses URL-safe alphabet (default: `false`)
- **Returns:** Base64-encoded string with padding

#### `decode(input: StringView, url_safe?: Bool = false) -> Bytes raise DecodeError`

Decodes a Base64 string to binary data.

- **Parameters:**
  - `input`: The Base64 string to decode
  - `url_safe`: If `true`, expects URL-safe alphabet (default: `false`)
- **Returns:** Decoded binary data
- **Raises:** `DecodeError` if the input is invalid

### Types

#### `Encoder`

Stateful encoder for streaming encoding.

**Methods:**
- `new() -> Encoder`: Creates a new encoder
- `encode_to(bytes: BytesView, cb: (Char) -> Unit, url_safe?: Bool, padding?: Bool)`: Encodes data and calls callback for each output character

#### `Decoder`

Stateful decoder for streaming decoding.

**Methods:**
- `new() -> Decoder`: Creates a new decoder
- `decode_to(input: StringView, cb: (Byte) -> Unit, url_safe?: Bool) raise DecodeError`: Decodes data and calls callback for each output byte

### Errors

#### `DecodeError`

Raised when decoding invalid Base64 data:
- `InvalidChar(Char)`: Invalid character in input

## Encoding Details

### Standard Alphabet
- Characters: `A-Z`, `a-z`, `0-9`, `+`, `/`
- Padding: `=`

### URL-Safe Alphabet
- Characters: `A-Z`, `a-z`, `0-9`, `-`, `_`
- Padding: `=`

## Notes

- Encoding always produces output with padding when using the `encode()` function
- Decoding handles both padded and unpadded input
- URL-safe variant is suitable for use in URLs and filenames
- The streaming API allows processing of large data without buffering
