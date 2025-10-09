#include "moonbit.h"
#include <errno.h>
#include <string.h>

MOONBIT_FFI_EXPORT
int
moonbit_maria_errno_ERANGE() {
  return ERANGE;
}

MOONBIT_FFI_EXPORT
char *
moonbit_maria_errno_strerror(int errnum) {
  return strerror(errnum);
}
