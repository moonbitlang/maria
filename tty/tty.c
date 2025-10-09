#include "moonbit.h"
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <sys/ioctl.h>
#include <sys/ttycom.h>
#include <termios.h>
#include <unistd.h>

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_tty_get_win_size(int32_t *size) {
  struct winsize ws;
  int result = ioctl(STDIN_FILENO, TIOCGWINSZ, &ws);
  if (result == -1) {
    return errno;
  }
  size[0] = ws.ws_row;
  size[1] = ws.ws_col;
  return 0;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_tty_set_raw_mode(int32_t fd) {
  int32_t flags = fcntl(fd, F_GETFL);
  flags |= O_NONBLOCK;
  if (fcntl(fd, F_SETFL, flags) == -1) {
    return errno;
  }
  struct termios term;
  if (tcgetattr(fd, &term) == -1) {
    return errno;
  }
  term.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
  term.c_oflag |= (ONLCR);
  term.c_cflag |= (CS8);
  term.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
  term.c_cc[VMIN] = 1;
  term.c_cc[VTIME] = 0;
  if (tcsetattr(fd, TCSADRAIN, &term) == -1) {
    return errno;
  }
  return 0;
}
