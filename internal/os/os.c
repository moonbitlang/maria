#include "moonbit.h"
#include <errno.h>
#include <pwd.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <unistd.h>

MOONBIT_FFI_EXPORT
const char *
moonbit_maria_os_getenv(moonbit_bytes_t key) {
  return getenv((const char *)key);
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_os_setenv(
  moonbit_bytes_t key,
  moonbit_bytes_t value,
  int overwrite
) {
  if (setenv((const char *)key, (const char *)value, overwrite) != 0) {
    return errno;
  } else {
    return 0;
  }
}

MOONBIT_FFI_EXPORT
int
moonbit_maria_os_unsetenv(moonbit_bytes_t key) {
  return unsetenv((const char *)key);
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_maria_os_getuid() {
  return (uint32_t)getuid();
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_os_getpwuid_r(
  uint32_t uid,
  moonbit_bytes_t pwd,
  char *buf,
  uint64_t buf_len,
  void **result
) {
  return getpwuid_r(
    uid, (struct passwd *)pwd, (char *)buf, buf_len, (struct passwd **)result
  );
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_os_passwd_sizeof() {
  return sizeof(struct passwd);
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_sysconf_SC_GETPW_R_SIZE_MAX() {
  return (int32_t)sysconf(_SC_GETPW_R_SIZE_MAX);
}

MOONBIT_FFI_EXPORT
char *
moonbit_maria_os_passwd_get_dir(moonbit_bytes_t pwd) {
  struct passwd *p = (struct passwd *)pwd;
  return p->pw_dir;
}

MOONBIT_FFI_EXPORT
int64_t
moonbit_maria_sysconf_SC_HOST_NAME_MAX(void) {
  return (int64_t)sysconf(_SC_HOST_NAME_MAX);
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_os_gethostname(moonbit_bytes_t name) {
  errno = 0;
  if (gethostname((char *)name, Moonbit_array_length(name)) == -1) {
    return errno;
  }
  return 0;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_os_chdir(moonbit_bytes_t path) {
  int result = chdir((const char *)path);
  if (result != 0) {
    return errno;
  } else {
    return 0;
  }
}

MOONBIT_FFI_EXPORT
void
moonbit_maria_os_exit(int32_t code) {
  exit(code);
}
