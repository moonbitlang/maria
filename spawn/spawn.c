#include "moonbit.h"
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
