#include <moonbit.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

MOONBIT_FFI_EXPORT
void *
moonbit_maria_c_malloc(uint64_t size) {
  return malloc(size);
}

MOONBIT_FFI_EXPORT
void
moonbit_maria_c_free(void *ptr) {
  free(ptr);
}
