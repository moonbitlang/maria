#include <execinfo.h>
#include <moonbit.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

MOONBIT_FFI_EXPORT
moonbit_bytes_t *
moonbit_maria_backtrace(int32_t n) {
  void **addresses = malloc(sizeof(void *) * n);
  int size = backtrace(addresses, n);
  char **symbols = backtrace_symbols(addresses, size);
  moonbit_bytes_t *result =
    (moonbit_bytes_t *)moonbit_make_ref_array(size, NULL);
  for (int i = 0; i < size; i++) {
    result[i] = moonbit_make_bytes(strlen(symbols[i]), 0);
    memcpy(result[i], symbols[i], strlen(symbols[i]));
  }
  free(symbols);
  return result;
}
