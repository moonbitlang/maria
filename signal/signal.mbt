///|
extern "c" fn signal_sigtstp() -> Int = "moonbit_maria_signal_sigtstp"

///|
pub let sigtstp : Int = signal_sigtstp()

///|
pub extern "c" fn signal(
  sig : Int,
  handler : FuncRef[(Int) -> Unit],
) -> FuncRef[(Int) -> Unit] = "signal"

///|
extern "c" fn signal_sig_dfl() -> FuncRef[(Int) -> Unit] = "moonbit_c_SIG_DFL"

///|
pub let sig_dfl : FuncRef[(Int) -> Unit] = signal_sig_dfl()

///|
extern "c" fn signal_sig_ign() -> FuncRef[(Int) -> Unit] = "moonbit_c_SIG_IGN"

///|
pub let sig_ign : FuncRef[(Int) -> Unit] = signal_sig_ign()

///|
extern "c" fn signal_sig_err() -> FuncRef[(Int) -> Unit] = "moonbit_c_SIG_ERR"

///|
pub let sig_err : FuncRef[(Int) -> Unit] = signal_sig_err()

///|
extern "c" fn signal_sigabrt() -> Int = "moonbit_c_SIGABRT"

///|
pub let sigabrt : Int = signal_sigabrt()

///|
extern "c" fn signal_sigfpe() -> Int = "moonbit_c_SIGFPE"

///|
pub let sigfpe : Int = signal_sigfpe()

///|
extern "c" fn signal_sigill() -> Int = "moonbit_c_SIGILL"

///|
pub let sigill : Int = signal_sigill()

///|
extern "c" fn signal_sigint() -> Int = "moonbit_c_SIGINT"

///|
pub let sigint : Int = signal_sigint()

///|
extern "c" fn signal_sigsegv() -> Int = "moonbit_c_SIGSEGV"

///|
pub let sigsegv : Int = signal_sigsegv()

///|
extern "c" fn signal_sigterm() -> Int = "moonbit_c_SIGTERM"

///|
pub let sigterm : Int = signal_sigterm()
