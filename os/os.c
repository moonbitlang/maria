#include "moonbit.h"
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>

MOONBIT_FFI_EXPORT
void
moonbit_maria_os_gettimeofday(int64_t *timeval) {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  timeval[0] = tv.tv_sec;
  timeval[1] = tv.tv_usec;
}

MOONBIT_FFI_EXPORT
char *
moonbit_maria_os_get_env(moonbit_bytes_t key) {
  char *val = getenv((const char *)key);
  return val;
}
