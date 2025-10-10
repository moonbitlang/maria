#include "moonbit.h"
#include <errno.h>
#include <stdlib.h>
#include <unistd.h>

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_fs_mkdtemp(moonbit_bytes_t template) {
  errno = 0;
  if (mkdtemp((char *)template)) {
    return 0;
  } else {
    return errno;
  }
}
