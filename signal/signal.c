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
