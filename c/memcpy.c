#include <moonbit.h>
#include <string.h>

MOONBIT_FFI_EXPORT
void
moonbit_c_memcpy(void *dest, void *src, uint64_t len) {
  memcpy(dest, src, len);
}
