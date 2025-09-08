#include <moonbit.h>
#include <stdio.h>
#include <string.h>

#include <readline/history.h>
#include <readline/readline.h>

MOONBIT_FFI_EXPORT
const char *moonbit_maria_readline(moonbit_bytes_t prompt) {
  return readline((char *)prompt);
}
