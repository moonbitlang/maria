///|
/// Returns the length of a C-style null-terminated string.
///
/// The pointer must reference a sequence of bytes terminated by `0`. The
/// result does not include the terminating null byte.
pub extern "c" fn strlen(str : Pointer[Byte]) -> UInt64 = "moonbit_maria_c_strlen"
