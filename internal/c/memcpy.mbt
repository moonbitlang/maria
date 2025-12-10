///|
/// Copies `len` bytes from `src` to `dest` using C `memcpy`.
///
/// The source and destination regions must not overlap. This is a thin
/// wrapper around the standard C library function and is inherently unsafe.
pub extern "c" fn memcpy(
  dest : Pointer[Byte],
  src : Pointer[Byte],
  len : UInt64,
) -> Unit = "moonbit_maria_c_memcpy"
