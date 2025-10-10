///|
#external
pub type Null

///|
extern "c" fn c_null() -> Null = "moonbit_maria_c_null"

///|
pub let null : Null = c_null()
