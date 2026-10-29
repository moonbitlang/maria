///|
extern "c" fn c_backtrace(n : Int32) -> FixedArray[Bytes] = "moonbit_maria_backtrace"

///|
pub fn backtrace(n~ : Int32 = 32) -> FixedArray[String] raise {
  c_backtrace(n).map(backtrace => @encoding/utf8.decode(backtrace))
}

///|
pub fn initialize() -> Unit {

}
