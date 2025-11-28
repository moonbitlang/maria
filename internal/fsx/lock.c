#include <fcntl.h>
#include <moonbit.h>

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_fsx_lock_file(int32_t fd) {
  struct flock fl;
  fl.l_type = F_WRLCK;
  fl.l_whence = SEEK_SET;
  fl.l_start = 0;
  fl.l_len = 0; // lock the whole file
  fl.l_pid = 0;
  return fcntl(fd, F_SETLK, &fl);
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_fsx_get_lock_owner(int32_t fd) {
  struct flock fl;
  fl.l_type = F_WRLCK; // or F_RDLCK, doesn't matter for F_GETLK
  fl.l_whence = SEEK_SET;
  fl.l_start = 0;
  fl.l_len = 0; // check the whole file
  fl.l_pid = 0;
  if (fcntl(fd, F_GETLK, &fl) == -1) {
    return -1; // error
  }
  if (fl.l_type == F_UNLCK) {
    return 0; // not locked
  }
  return fl.l_pid; // return the PID of the lock owner
}
