# C Interop Package

The `@c` package provides low-level building blocks for interpolating with C
code and raw memory from MoonBit. It focuses on a small, well-defined surface
area:

- An opaque `Pointer[T]` type for unmanaged memory
- Null pointer modelling via `Null` and `Pointer::null`
- Thin wrappers around `malloc` / `free`
- Bindings for `memcpy` and `strlen`
- An emergency `exit` helper built on top of C `_exit`

Most of these APIs are inherently unsafe: they bypass MoonBit's usual safety
checks and require careful manual reasoning about lifetimes, ownership, and
pointer validity.

## Pointer Basics

```mbt check
///|
test {
  // Allocate space for a single Int
  let ptr : @c.Pointer[Int] = @c.malloc(8)
  // Write a value through the pointer
  ptr.store(42)
  // Read the value back
  let value = ptr.load()
  assert_eq(value, 42)
  // Always free what you allocate
  @c.free(ptr)
}
```

The `Pointer[T]` type is opaque and does not carry any automatic lifetime
management. It provides helpers like:

- `Pointer::null()` / `Pointer::is_null()`
- Indexing via `ptr[i]` powered by the `Load`/`Store` traits

## Working with C Strings

The `strlen` binding exposes the standard C string length routine. It expects a
null-terminated sequence of bytes and returns the length without the
terminating `0` byte:

```mbt check
///|
test {
  let s : Pointer[Byte] = @c.malloc(6)
  s[0] = 'h'
  s[1] = 'e'
  s[2] = 'l'
  s[3] = 'l'
  s[4] = 'o'
  s[5] = 0
  json_inspect(strlen(s), content="5")
  @c.free(s)
}
```

## Memory Copy with `memcpy`

`memcpy` copies a fixed number of bytes between two pointer regions. The
regions must **not** overlap:

```mbt check
///|
test {
  let src : Pointer[Byte] = malloc(4)
  let dst : Pointer[Byte] = malloc(4)
  src[0] = 1
  src[1] = 2
  src[2] = 3
  src[3] = 4
  @c.memcpy(dst.cast(), src.cast(), 4)
  assert_eq(dst[0], 1)
  assert_eq(dst[3], 4)
  @c.free(src)
  @c.free(dst)
}
```

## Process Exit

The `exit` helper exposes C `_exit` as a last-resort termination primitive:

```mbt check
///|
test {
  @c.exit(0)
}
```

This is intended for low-level runtime code and should generally not be used in
high-level application logic.
