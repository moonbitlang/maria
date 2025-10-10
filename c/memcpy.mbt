///|
pub extern "c" fn memcpy(
  dest : Pointer[Byte],
  src : Pointer[Byte],
  len : UInt64,
) -> Unit = "moonbit_c_memcpy"

///|
#borrow(source)
pub extern "c" fn memcpy_from_bytes(
  dest : Pointer[Byte],
  source : Bytes,
  length : UInt64,
) -> Unit = "moonbit_c_memcpy"

///|
#borrow(dest)
pub extern "c" fn memcpy_to_bytes(
  dest : Bytes,
  source : Pointer[Byte],
  length : UInt64,
) -> Unit = "moonbit_c_memcpy"
