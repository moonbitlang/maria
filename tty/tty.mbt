///|
#borrow(size)
extern "c" fn tty_get_win_size(size : FixedArray[Int]) -> Int = "moonbit_maria_tty_get_win_size"

///|
pub struct Size {
  row : Int
  col : Int
} derive(ToJson)

///|
pub fn window_size() -> Size raise {
  let buf : FixedArray[Int] = [0, 0]
  let result = tty_get_win_size(buf)
  if result != 0 {
    raise @errno.Errno(result)
  }
  Size::{ row: buf[0], col: buf[1] }
}

///|
extern "c" fn tty_set_raw_mode(fd : Int) -> Int = "moonbit_maria_tty_set_raw_mode"

///|
pub fn set_raw_mode(fd : Int) -> Unit raise {
  let result = tty_set_raw_mode(fd)
  if result != 0 {
    raise @errno.Errno(result)
  }
}
