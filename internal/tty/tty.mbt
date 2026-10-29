///|
extern "c" fn tty_is_a_tty(fd : Int32) -> Int32 = "moonbit_maria_tty_is_a_tty"

///|
#callsite(autofill(loc))
pub fn isatty(fd : Int32, loc~ : SourceLoc) -> Bool raise {
  let result = tty_is_a_tty(fd)
  if result == 0 {
    let errno = @errno.get()
    if errno == @errno.ebadf {
      abort("\{loc}: Not a valid file descriptor: \{fd}")
    } else if errno == @errno.enotty {
      return false
    } else {
      raise @errno.Errno(errno)
    }
  }
  return true
}

///|
#borrow(size)
extern "c" fn tty_get_win_size(size : FixedArray[Int32]) -> Int32 = "moonbit_maria_tty_get_win_size"

///|
pub struct Size {
  row : Int32
  col : Int32
} derive(ToJson)

///|
pub fn window_size() -> Size raise {
  let buf : FixedArray[Int32] = [0, 0]
  let result = tty_get_win_size(buf)
  if result != 0 {
    raise @errno.Errno(result)
  }
  Size::{ row: buf[0], col: buf[1], }
}

///|
extern "c" fn tty_set_raw_mode(fd : Int32) -> Int32 = "moonbit_maria_tty_set_raw_mode"

///|
pub fn set_raw_mode(fd : Int32) -> Unit raise {
  let result = tty_set_raw_mode(fd)
  if result != 0 {
    raise @errno.Errno(result)
  }
}

///|
pub extend Size with ToJson::{to_json}
