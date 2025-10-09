#include "moonbit.h"
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <unistd.h>

MOONBIT_FFI_EXPORT
void
moonbit_maria_os_gettimeofday(int64_t *timeval) {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  timeval[0] = tv.tv_sec;
  timeval[1] = tv.tv_usec;
}

MOONBIT_FFI_EXPORT
const char *
moonbit_maria_os_get_env(moonbit_bytes_t key) {
  return getenv((const char *)key);
}

MOONBIT_FFI_EXPORT
int
moonbit_maria_os_getcwd(moonbit_bytes_t buf) {
  errno = 0;
  char *val = getcwd((char *)buf, Moonbit_array_length(buf));
  if (!val) {
    return errno;
  }
  return 0;
}

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
