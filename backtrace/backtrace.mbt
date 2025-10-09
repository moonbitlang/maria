///|
extern "c" fn c_backtrace(n : Int) -> FixedArray[Bytes] = "moonbit_maria_backtrace"

///|
pub fn backtrace(n? : Int = 32) -> FixedArray[String] raise {
  c_backtrace(n).map(@encoding/utf8.decode(_))
}

///|
pub fn initialize() -> Unit {

}
