#include "moonbit.h"
#include <stdint.h>
#include <unistd.h>

MOONBIT_FFI_EXPORT
int64_t
moonbit_maria_fs_readlink(
  moonbit_bytes_t path,
  moonbit_bytes_t buf,
  uint64_t bufsize
) {
  return (int64_t)readlink((const char *)path, (char *)buf, (size_t)bufsize);
}
