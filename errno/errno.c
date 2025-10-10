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

MOONBIT_FFI_EXPORT
int
moonbit_maria_errno_ENAMETOOLONG() {
  return ENAMETOOLONG;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_errno_get() {
  return errno;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_errno_set(int32_t err) {
  errno = err;
  return errno;
}
