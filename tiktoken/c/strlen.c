#include <moonbit.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

MOONBIT_FFI_EXPORT
uint64_t
moonbit_maria_c_strlen(const char *str) {
  return (uint64_t)strlen(str);
}
