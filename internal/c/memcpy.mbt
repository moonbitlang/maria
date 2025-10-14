///|
pub extern "c" fn memcpy(
  dest : Pointer[Byte],
  src : Pointer[Byte],
  len : UInt64,
) -> Unit = "moonbit_maria_c_memcpy"
