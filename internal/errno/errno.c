#include "moonbit.h"
#include <errno.h>
#include <string.h>

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_errno_ERANGE(void) {
  return ERANGE;
}

MOONBIT_FFI_EXPORT
char *
moonbit_maria_errno_strerror(int errnum) {
  return strerror(errnum);
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_errno_ENAMETOOLONG(void) {
  return ENAMETOOLONG;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_errno_EBADF(void) {
  return EBADF;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_errno_ENOTTY(void) {
  return ENOTTY;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_errno_get(void) {
  return errno;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_errno_EEXIST(void) {
  return EEXIST;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_errno_EINVAL(void) {
  return EINVAL;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_errno_ENOENT(void) {
  return ENOENT;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_errno_EAGAIN(void) {
  return EAGAIN;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_errno_EACCES(void) {
  return EACCES;
}
