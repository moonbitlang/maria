///|
extern "c" fn c_EOF() -> Int = "moonbit_c_EOF"

///|
pub let eof : Int = c_EOF()

///|
extern "c" fn c_stdin() -> FILE = "moonbit_c_stdin"

///|
pub let stdin : FILE = c_stdin()

///|
extern "c" fn c_stdout() -> FILE = "moonbit_c_stdout"

///|
pub let stdout : FILE = c_stdout()

///|
extern "c" fn c_stderr() -> FILE = "moonbit_c_stderr"

///|
pub let stderr : FILE = c_stderr()
