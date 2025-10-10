///|
extern "c" fn signal_sigtstp() -> Int = "moonbit_maria_signal_sigtstp"

///|
pub let sigtstp : Int = signal_sigtstp()
