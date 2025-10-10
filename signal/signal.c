#include "moonbit.h"
#include <signal.h>

MOONBIT_FFI_EXPORT
void (*moonbit_maria_signal_SIG_DFL(void))(int) { return SIG_DFL; }

MOONBIT_FFI_EXPORT
void (*moonbit_maria_signal_SIG_IGN(void))(int) { return SIG_IGN; }

MOONBIT_FFI_EXPORT
void (*moonbit_maria_signal_SIG_ERR(void))(int) { return SIG_ERR; }

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_signal_SIGABRT(void) {
  return SIGABRT;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_signal_SIGFPE(void) {
  return SIGFPE;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_signal_SIGILL(void) {
  return SIGILL;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_signal_SIGINT(void) {
  return SIGINT;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_signal_SIGSEGV(void) {
  return SIGSEGV;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_signal_SIGTERM(void) {
  return SIGTERM;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_signal_sigtstp(void) {
#ifdef SIGTSTP
  return SIGTSTP;
#else
  return -1;
#endif
}
