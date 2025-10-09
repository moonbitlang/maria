# `moonbitlang/maria/backtrace`

Backtrace library using
[backtrace(3)](https://man7.org/linux/man-pages/man3/backtrace.3.html).

One must call `@backtrace.initialize()` at the start of the program to
enable the backtrace support, otherwise the compilation will fail.
