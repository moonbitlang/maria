#include "moonbit.h"
#include <errno.h>
#include <sys/stat.h>

MOONBIT_FFI_EXPORT
int
moonbit_maria_fs_stat_sizeof() {
  return sizeof(struct stat);
}

MOONBIT_FFI_EXPORT
int
moonbit_maria_fs_stat_sync(moonbit_bytes_t path, moonbit_bytes_t buf) {
  errno = 0;
  int result = stat((const char *)path, (struct stat *)buf);
  if (result == -1) {
    return errno;
  } else {
    return 0;
  }
}

MOONBIT_FFI_EXPORT
int64_t
moonbit_maria_fs_stat_get_mtime(moonbit_bytes_t buf) {
  struct stat *st = (struct stat *)buf;
  return (int64_t)st->st_mtime;
}

MOONBIT_FFI_EXPORT
int64_t
moonbit_maria_fs_stat_get_atime(moonbit_bytes_t buf) {
  struct stat *st = (struct stat *)buf;
  return (int64_t)st->st_atime;
}
