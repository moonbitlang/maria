#include <moonbit.h>
#include <unistd.h>

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_fsx_ftruncate(int32_t fd, int64_t length) {
  return ftruncate(fd, length);
}
