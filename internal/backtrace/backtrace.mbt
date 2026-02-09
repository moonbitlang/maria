///|
extern "c" fn c_backtrace(n : Int) -> FixedArray[Bytes] = "moonbit_maria_backtrace"

///|
pub fn backtrace(n? : Int = 32) -> FixedArray[String] raise {
  c_backtrace(n).map(backtrace => @encoding/utf8.decode(backtrace))
}

///|
pub fn initialize() -> Unit {

}
