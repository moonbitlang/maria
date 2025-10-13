# `moonbitlang/maria/c`

Low-level C interop utilities for working with C pointers and memory.

## Overview

This package provides essential utilities for interfacing with C code, including pointer manipulation, memory operations, and type conversions.

## Usage

### Working with Pointers

```moonbit
// Create a null pointer
let null_ptr : @c.Pointer[Int] = @c.Pointer::null()
null_ptr.is_null() // true

// Check pointer equality
let ptr1 = @c.Pointer::null()
let ptr2 = @c.Pointer::null()
ptr1 == ptr2 // true
```

### Loading and Storing Values

```moonbit
// Pointers support loading and storing primitive types
// Example with byte array
let bytes = Bytes::make(10, 0)
// ptr operations would work with external C memory
let _ = bytes
```

### String Operations

```moonbit
// C string length calculation
// @c.strlen(c_string_pointer)
let _ = 0
```

## API Reference

### Types

#### `Pointer[T]`

A generic pointer type for C interop.

**Type Alias:** `Ptr[T]`

**Methods:**
- `cast[U]() -> Pointer[U]`: Cast pointer to another type
- `is_null() -> Bool`: Check if pointer is null
- `null() -> Pointer[T]`: Create a null pointer
- `op_get(index: Int) -> T`: Load value at index (requires `T: Load`)
- `op_set(index: Int, value: T)`: Store value at index (requires `T: Store`)
- `load(offset?: Int) -> T`: Load value at offset
- `store(offset?: Int, value: T)`: Store value at offset

**Traits:**
- `Eq`: Pointers can be compared for equality

### Traits

#### `Load`

Trait for types that can be loaded from C pointers.

Implemented for: `Byte`, `Int16`, `UInt16`, `Int`, `UInt`, `Int64`, `UInt64`, `Float`, `Double`

#### `Store`

Trait for types that can be stored to C pointers.

Implemented for: `Byte`, `Int16`, `UInt16`, `Int`, `UInt`, `Int64`, `UInt64`, `Float`, `Double`

### Functions

#### `strlen(ptr: Pointer[Byte]) -> Int`

Computes the length of a null-terminated C string.

#### `memcpy(dest: Pointer[Byte], src: Pointer[Byte], n: Int) -> Unit`

Copies n bytes from src to dest.

#### `malloc(size: Int) -> Pointer[Byte]`

Allocates memory of the given size.

#### `exit(status: Int) -> Unit`

Exits the program with the given status code.

## Notes

- This package is for low-level C interop
- Pointer operations are unsafe and require careful use
- Memory allocated with `malloc` should be properly managed
- Null pointer checks are important for safety
- Use with `#borrow` and `extern "c"` annotations for FFI
