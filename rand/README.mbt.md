# `moonbitlang/maria/rand`

Cryptographically secure random number generation.

## Overview

This package provides access to cryptographically secure random number generation using system-level entropy sources. It offers both raw random bytes and higher-level random number generation.

## Usage

### Generate Random Bytes

```moonbit
///|
test "random bytes" {
  let random_data = @rand.bytes(16)
  @json.inspect(random_data.length(), content=16)
  // Each byte is random
}
```

### Generate Random UInt64

```moonbit
///|
test "random uint64" {
  let random_num = @rand.uint64()
  // random_num is a cryptographically secure random UInt64
  let _ = random_num
}
```

### ChaCha8 Random Generator

```moonbit
///|
test "chacha8 rng" {
  // Create a seeded random number generator
  let rng = @rand.chacha8()
  let num = rng.int()
  let _ = num
}
```

## API Reference

### Functions

#### `bytes(n: Int) -> Bytes raise`

Generates `n` cryptographically secure random bytes.

- **Parameters:**
  - `n`: Number of random bytes to generate
- **Returns:** A `Bytes` buffer containing random data
- **Raises:** `@errno.Errno` if the system random source fails

#### `uint64() -> UInt64 raise`

Generates a cryptographically secure random 64-bit unsigned integer.

- **Returns:** A random `UInt64` value
- **Raises:** `@errno.Errno` if the system random source fails

#### `chacha8(seed?: Bytes) -> @random.Rand`

Creates a ChaCha8-based pseudo-random number generator.

- **Parameters:**
  - `seed`: Optional seed for the generator (uses system entropy if not provided)
- **Returns:** A `@random.Rand` instance

## Notes

- This package uses system-level entropy sources (e.g., `/dev/urandom` on Unix systems)
- Random bytes are suitable for cryptographic purposes
- The ChaCha8 generator is a fast, high-quality pseudo-random number generator
- All functions that access system entropy may raise `@errno.Errno` on system failures
