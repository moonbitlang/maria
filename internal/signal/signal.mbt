///|
extern "c" fn signal_sigtstp() -> Int = "moonbit_maria_signal_sigtstp"

///|
fn check_signal_value(value : Int, name : String) -> Int {
  if value == -1 {
    abort("\{name} not supported on this platform")
  }
  value
}

///|
pub let sigtstp : Int = check_signal_value(signal_sigtstp(), "SIGTSTP")

///|
extern "c" fn signal_sigterm() -> Int = "moonbit_maria_signal_sigterm"

///|
pub let sigterm : Int = check_signal_value(signal_sigterm(), "SIGTERM")

///|
extern "c" fn signal_sigkill() -> Int = "moonbit_maria_signal_sigkill"

///|
pub let sigkill : Int = check_signal_value(signal_sigkill(), "SIGKILL")
