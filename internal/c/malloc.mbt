///|
/// Low-level wrapper around the C `malloc` function.
///
/// `c_malloc` allocates `size` bytes of raw memory and returns a pointer to
/// uninitialized storage. The returned memory must eventually be freed via
/// `c_free` (or `free`).
extern "c" fn c_malloc(size : UInt64) -> Pointer[Unit] = "moonbit_maria_c_malloc"

///|
/// Allocates `size` bytes of memory and casts it to `Pointer[T]`.
///
/// This is a thin, unsafe wrapper around `c_malloc`: the caller is
/// responsible for choosing an appropriate `T`, initializing the memory, and
/// eventually freeing it with `free`.
pub fn[T] malloc(size : UInt64) -> Pointer[T] {
  c_malloc(size).cast()
}

///|
/// Low-level wrapper around the C `free` function.
extern "c" fn c_free(ptr : Pointer[Unit]) = "moonbit_maria_c_free"

///|
/// Releases memory previously allocated with `malloc` / `c_malloc`.
///
/// After calling `free`, the given pointer must not be dereferenced again.
pub fn[T] free(ptr : Pointer[T]) -> Unit {
  c_free(ptr.cast())
}
