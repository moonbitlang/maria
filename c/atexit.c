#include <moonbit.h>
#include <stdlib.h>

MOONBIT_FFI_EXPORT
int32_t
moonbit_c_atexit(void (*func)(void)) {
  return atexit(func);
}
