///|
extern "c" fn signal_sigtstp() -> Int32 = "moonbit_maria_signal_sigtstp"

///|
fn check_signal_value(value : Int32, name : String) -> Int32 {
  if value == -1 {
    abort("\{name} not supported on this platform")
  }
  value
}

///|
pub let sigtstp : Int32 = check_signal_value(signal_sigtstp(), "SIGTSTP")

///|
extern "c" fn signal_sigterm() -> Int32 = "moonbit_maria_signal_sigterm"

///|
pub let sigterm : Int32 = check_signal_value(signal_sigterm(), "SIGTERM")

///|
extern "c" fn signal_sigkill() -> Int32 = "moonbit_maria_signal_sigkill"

///|
pub let sigkill : Int32 = check_signal_value(signal_sigkill(), "SIGKILL")
