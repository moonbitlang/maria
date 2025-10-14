///|
extern "c" fn _exit(status : Int) = "exit"

///|
pub fn[T] exit(status : Int) -> T {
  _exit(status)
  abort("exit should never return")
}
