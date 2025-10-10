#include <moonbit.h>
#include <stdint.h>

MOONBIT_FFI_EXPORT
uint32_t
moonbit_maria_c_uintptr_to_byte(uintptr_t p) {
  return (uint8_t)p;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_c_uintptr_to_int16(uintptr_t p) {
  return (int16_t)p;
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_maria_c_uintptr_to_uint16(uintptr_t p) {
  return (uint16_t)p;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_maria_c_uintptr_to_int(uintptr_t p) {
  return (int32_t)p;
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_maria_c_uintptr_to_uint(uintptr_t p) {
  return (uint32_t)p;
}

MOONBIT_FFI_EXPORT
int64_t
moonbit_maria_c_uintptr_to_int64(uintptr_t p) {
  return (int64_t)p;
}

MOONBIT_FFI_EXPORT
uint64_t
moonbit_maria_c_uintptr_to_uint64(uintptr_t p) {
  return (uint64_t)p;
}

MOONBIT_FFI_EXPORT
uintptr_t
moonbit_maria_c_uintptr_from_byte(uint32_t b) {
  return (uintptr_t)b;
}

MOONBIT_FFI_EXPORT
uintptr_t
moonbit_maria_c_uintptr_from_int16(int32_t i) {
  return (uintptr_t)i;
}

MOONBIT_FFI_EXPORT
uintptr_t
moonbit_maria_c_uintptr_from_uint16(uint32_t u) {
  return (uintptr_t)u;
}

MOONBIT_FFI_EXPORT
uintptr_t
moonbit_maria_c_uintptr_from_int(int32_t i) {
  return (uintptr_t)i;
}

MOONBIT_FFI_EXPORT
uintptr_t
moonbit_maria_c_uintptr_from_uint(uint32_t u) {
  return (uintptr_t)u;
}

MOONBIT_FFI_EXPORT
uintptr_t
moonbit_maria_c_uintptr_from_int64(int64_t i) {
  return (uintptr_t)i;
}

MOONBIT_FFI_EXPORT
uintptr_t
moonbit_maria_c_uintptr_from_uint64(uint64_t u) {
  return (uintptr_t)u;
}
