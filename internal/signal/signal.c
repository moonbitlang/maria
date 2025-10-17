#include "moonbit.h"
#include <signal.h>

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_signal_sigtstp(void) {
#ifdef SIGTSTP
  return SIGTSTP;
#else
  return -1;
#endif
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_signal_sigterm(void) {
#ifdef SIGTERM
  return SIGTERM;
#else
  return -1;
#endif
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_signal_sigkill(void) {
#ifdef SIGKILL
  return SIGKILL;
#else
  return -1;
#endif
}
