#include "moonbit.h"
#include <errno.h>
#include <sys/random.h>

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_rand_bytes(moonbit_bytes_t buf) {
  int32_t result = getentropy(buf, Moonbit_array_length(buf));
  if (result == -1) {
    return errno;
  } else {
    return 0;
  }
}
