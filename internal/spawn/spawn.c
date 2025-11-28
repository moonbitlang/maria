#include "moonbit.h"
#include <errno.h>
#include <signal.h>
#include <unistd.h>

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_process_getpid(void) {
  return (int32_t)getpid();
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_process_getppid(void) {
  return (int32_t)getppid();
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_process_kill(int32_t pid, int32_t sig) {
  int32_t result = kill((pid_t)pid, sig);
  if (result == -1) {
    return errno;
  } else {
    return 0;
  }
}
