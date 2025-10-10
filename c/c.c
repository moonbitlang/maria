#include "moonbit.h"
#include <stdint.h>

MOONBIT_FFI_EXPORT
void *
moonbit_ffi_make_closure(void *function, void *callback) {
  return callback;
}

MOONBIT_FFI_EXPORT
void *
moonbit_c_null() {
  return NULL;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_c_is_null(void *ptr) {
  return ptr == NULL;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_c_not_null(void *ptr) {
  return ptr != NULL;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_c_pointer_equal(void *ptr1, void *ptr2) {
  return ptr1 == ptr2;
}

MOONBIT_FFI_EXPORT
void *
moonbit_c_identity(void *pointer) {
  return pointer;
}

MOONBIT_FFI_EXPORT
char
moonbit_c_load_byte(void *pointer, int32_t index) {
  return ((char *)pointer)[index];
}

MOONBIT_FFI_EXPORT
int16_t
moonbit_c_load_int16(void *pointer, int32_t index) {
  return ((int16_t *)pointer)[index];
}

MOONBIT_FFI_EXPORT
uint16_t
moonbit_c_load_uint16(void *pointer, int32_t index) {
  return ((uint16_t *)pointer)[index];
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_c_load_int(void *pointer, int32_t index) {
  return ((int32_t *)pointer)[index];
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_c_load_uint(void *pointer, int32_t index) {
  return ((uint32_t *)pointer)[index];
}

MOONBIT_FFI_EXPORT
int64_t
moonbit_c_load_int64(void *pointer, int32_t index) {
  return ((int64_t *)pointer)[index];
}

MOONBIT_FFI_EXPORT
uint64_t
moonbit_c_load_uint64(void *pointer, int32_t index) {
  return ((uint64_t *)pointer)[index];
}

MOONBIT_FFI_EXPORT
float
moonbit_c_load_float(void *pointer, int32_t index) {
  return ((float *)pointer)[index];
}

MOONBIT_FFI_EXPORT
double
moonbit_c_load_double(void *pointer, int32_t index) {
  return ((double *)pointer)[index];
}

MOONBIT_FFI_EXPORT
void
moonbit_c_store_byte(void *pointer, int32_t index, char value) {
  ((char *)pointer)[index] = value;
}

MOONBIT_FFI_EXPORT
void
moonbit_c_store_int16(void *pointer, int32_t index, int16_t value) {
  ((int16_t *)pointer)[index] = value;
}

MOONBIT_FFI_EXPORT
void
moonbit_c_store_uint16(void *pointer, int32_t index, uint16_t value) {
  ((uint16_t *)pointer)[index] = value;
}

MOONBIT_FFI_EXPORT
void
moonbit_c_store_int(void *pointer, int32_t index, int32_t value) {
  ((int32_t *)pointer)[index] = value;
}

MOONBIT_FFI_EXPORT
void
moonbit_c_store_uint(void *pointer, int32_t index, uint32_t value) {
  ((uint32_t *)pointer)[index] = value;
}

MOONBIT_FFI_EXPORT
void
moonbit_c_store_int64(void *pointer, int32_t index, int64_t value) {
  ((int64_t *)pointer)[index] = value;
}

MOONBIT_FFI_EXPORT
void
moonbit_c_store_uint64(void *pointer, int32_t index, uint64_t value) {
  ((uint64_t *)pointer)[index] = value;
}

MOONBIT_FFI_EXPORT
void
moonbit_c_store_float(void *pointer, int32_t index, float value) {
  ((float *)pointer)[index] = value;
}

MOONBIT_FFI_EXPORT
void
moonbit_c_store_double(void *pointer, int32_t index, double value) {
  ((double *)pointer)[index] = value;
}
