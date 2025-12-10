///|
/// Native helper for reading the target of a symbolic link.
///
/// This wraps the platform `readlink` function and is not exposed
/// directly; see `readlink` for the public API.
#borrow(path, buf)
extern "c" fn fs_readlink(
  path : Bytes,
  buf : FixedArray[Byte],
  bufsize : UInt64,
) -> Int64 = "moonbit_maria_fs_readlink"

///|
/// Read the target path of the symbolic link at `path`.
///
/// The `bufsize` parameter controls the initial buffer size used when
/// calling the underlying `readlink`; it is automatically grown when
/// needed. On error this raises an `@errno.Errno`.
pub fn readlink(path : String, bufsize? : UInt64 = 1024) -> String raise {
  guard bufsize > 0 else {
    abort("bufsize must be greater than 0, got \{bufsize}")
  }
  let bytes = @encoding/utf8.encode(path)
  let mut buf : FixedArray[Byte] = FixedArray::make(bufsize.to_int(), 0)
  let mut bufsize : UInt64 = bufsize
  loop fs_readlink(bytes, buf, bufsize) {
    _..<0 => raise @errno.Errno(@errno.get())
    n =>
      // If the buffer was too small, try again with a larger buffer
      if n.reinterpret_as_uint64() == bufsize {
        bufsize = bufsize * 2
        buf = FixedArray::make(bufsize.to_int(), 0)
        continue fs_readlink(bytes, buf, bufsize)
      } else {
        return @encoding/utf8.decode(
          buf.unsafe_reinterpret_as_bytes()[0:n.to_int()],
        )
      }
  }
}
