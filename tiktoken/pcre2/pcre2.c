#include <stdint.h>
#define PCRE2_CODE_UNIT_WIDTH 16
#include "pcre2.h"
#include <moonbit.h>

#define static_assert_type_equal(type, expected)                               \
  _Static_assert(                                                              \
    _Generic((type)0, expected: 1, default: 0), #type " is not " #expected     \
  )

int32_t
moonbit_pcre2_ERROR_NOMATCH() {
  PCRE2_SPTR16 a;
  return PCRE2_ERROR_NOMATCH;
}

int32_t
moonbit_pcre2_ERROR_NOMEMORY() {
  return PCRE2_ERROR_NOMEMORY;
}

uint32_t
moonbit_pcre2_NOTEMPTY_ATSTART() {
  return PCRE2_NOTEMPTY_ATSTART;
}

uint32_t
moonbit_pcre2_ANCHORED() {
  return PCRE2_ANCHORED;
}

uint32_t
moonbit_pcre2_INFO_ALLOPTIONS() {
  return PCRE2_INFO_ALLOPTIONS;
}

uint32_t
moonbit_pcre2_INFO_ARGOPTIONS() {
  return PCRE2_INFO_ARGOPTIONS;
}

uint32_t
moonbit_pcre2_INFO_BACKREFMAX() {
  return PCRE2_INFO_BACKREFMAX;
}

uint32_t
moonbit_pcre2_INFO_BSR() {
  return PCRE2_INFO_BSR;
}

uint32_t
moonbit_pcre2_INFO_CAPTURECOUNT() {
  return PCRE2_INFO_CAPTURECOUNT;
}

uint32_t
moonbit_pcre2_INFO_DEPTHLIMIT() {
  return PCRE2_INFO_DEPTHLIMIT;
}

uint32_t
moonbit_pcre2_INFO_EXTRAOPTIONS() {
  return PCRE2_INFO_EXTRAOPTIONS;
}

uint32_t
moonbit_pcre2_INFO_FIRSTBITMAP() {
  return PCRE2_INFO_FIRSTBITMAP;
}

uint32_t
moonbit_pcre2_INFO_FIRSTCODETYPE() {
  return PCRE2_INFO_FIRSTCODETYPE;
}

uint32_t
moonbit_pcre2_INFO_FIRSTCODEUNIT() {
  return PCRE2_INFO_FIRSTCODEUNIT;
}

uint32_t
moonbit_pcre2_INFO_FRAMESIZE() {
  return PCRE2_INFO_FRAMESIZE;
}

uint32_t
moonbit_pcre2_INFO_HASBACKSLASHC() {
  return PCRE2_INFO_HASBACKSLASHC;
}

uint32_t
moonbit_pcre2_INFO_HASCRORLF() {
  return PCRE2_INFO_HASCRORLF;
}

uint32_t
moonbit_pcre2_INFO_HEAPLIMIT() {
  return PCRE2_INFO_HEAPLIMIT;
}

uint32_t
moonbit_pcre2_INFO_JCHANGED() {
  return PCRE2_INFO_JCHANGED;
}

uint32_t
moonbit_pcre2_INFO_JITSIZE() {
  return PCRE2_INFO_JITSIZE;
}

uint32_t
moonbit_pcre2_INFO_LASTCODETYPE() {
  return PCRE2_INFO_LASTCODETYPE;
}

uint32_t
moonbit_pcre2_INFO_LASTCODEUNIT() {
  return PCRE2_INFO_LASTCODEUNIT;
}

uint32_t
moonbit_pcre2_INFO_MATCHEMPTY() {
  return PCRE2_INFO_MATCHEMPTY;
}

uint32_t
moonbit_pcre2_INFO_MATCHLIMIT() {
  return PCRE2_INFO_MATCHLIMIT;
}

uint32_t
moonbit_pcre2_INFO_MAXLOOKBEHIND() {
  return PCRE2_INFO_MAXLOOKBEHIND;
}

uint32_t
moonbit_pcre2_INFO_NAMECOUNT() {
  return PCRE2_INFO_NAMECOUNT;
}

uint32_t
moonbit_pcre2_INFO_NAMEENTRYSIZE() {
  return PCRE2_INFO_NAMEENTRYSIZE;
}

uint32_t
moonbit_pcre2_INFO_NAMETABLE() {
  return PCRE2_INFO_NAMETABLE;
}

uint32_t
moonbit_pcre2_INFO_NEWLINE() {
  return PCRE2_INFO_NEWLINE;
}

uint32_t
moonbit_pcre2_INFO_SIZE() {
  return PCRE2_INFO_SIZE;
}

uint32_t
moonbit_pcre2_NEWLINE_CR() {
  return PCRE2_NEWLINE_CR;
}

uint32_t
moonbit_pcre2_NEWLINE_LF() {
  return PCRE2_NEWLINE_LF;
}

uint32_t
moonbit_pcre2_NEWLINE_CRLF() {
  return PCRE2_NEWLINE_CRLF;
}

uint32_t
moonbit_pcre2_NEWLINE_ANY() {
  return PCRE2_NEWLINE_ANY;
}

uint32_t
moonbit_pcre2_NEWLINE_ANYCRLF() {
  return PCRE2_NEWLINE_ANYCRLF;
}

uint32_t
moonbit_pcre2_NEWLINE_NUL() {
  return PCRE2_NEWLINE_NUL;
}

uint32_t
moonbit_pcre2_SUBSTITUTE_OVERFLOW_LENGTH() {
  return PCRE2_SUBSTITUTE_OVERFLOW_LENGTH;
}

typedef struct moonbit_pcre2_code {
  pcre2_code *code;
} moonbit_pcre2_code;

void
moonbit_pcre2_code_finalize(void *object) {
  moonbit_pcre2_code *code = (moonbit_pcre2_code *)object;
  if (code) {
    if (code->code) {
      pcre2_code_free(code->code);
    }
  }
}

int32_t
moonbit_pcre2_get_error_message(
  int32_t error_code,
  moonbit_string_t buffer,
  PCRE2_SIZE buffer_length
) {
  int32_t written = pcre2_get_error_message(error_code, buffer, buffer_length);
  moonbit_decref(buffer);
  return written;
}

moonbit_pcre2_code *
moonbit_pcre2_compile(
  moonbit_string_t pattern,
  PCRE2_SIZE length,
  uint32_t options,
  int32_t *error_code,
  PCRE2_SIZE *error_offset,
  pcre2_compile_context *context
) {
  pcre2_code *code =
    pcre2_compile(pattern, length, options, error_code, error_offset, context);
  moonbit_decref(pattern);
  moonbit_decref(error_code);
  moonbit_decref(error_offset);
  moonbit_pcre2_code *moonbit_code =
    (moonbit_pcre2_code *)moonbit_make_external_object(
      moonbit_pcre2_code_finalize, sizeof(pcre2_code *)
    );
  moonbit_code->code = code;
  return moonbit_code;
}

typedef struct moonbit_pcre2_match_data {
  pcre2_match_data *match_data;
} moonbit_pcre2_match_data;

static inline void
moonbit_pcre2_match_data_finalize(void *object) {
  moonbit_pcre2_match_data *match_data = (moonbit_pcre2_match_data *)object;
  if (match_data) {
    if (match_data->match_data) {
      pcre2_match_data_free(match_data->match_data);
    }
  }
}

moonbit_pcre2_match_data *
moonbit_pcre2_match_data_create_from_pattern(
  moonbit_pcre2_code *code,
  pcre2_general_context *context
) {
  pcre2_match_data *match_data =
    pcre2_match_data_create_from_pattern(code->code, context);
  moonbit_decref(code);
  moonbit_pcre2_match_data *moonbit_match_data =
    (moonbit_pcre2_match_data *)moonbit_make_external_object(
      moonbit_pcre2_match_data_finalize, sizeof(pcre2_match_data *)
    );
  moonbit_match_data->match_data = match_data;
  return moonbit_match_data;
}

PCRE2_SIZE *
moonbit_pcre2_get_ovector_pointer(moonbit_pcre2_match_data *match_data) {
  PCRE2_SIZE *ovector = pcre2_get_ovector_pointer(match_data->match_data);
  moonbit_decref(match_data);
  return ovector;
}

PCRE2_SIZE
moonbit_pcre2_get_startchar(
  moonbit_pcre2_match_data *match_data
) {
  PCRE2_SIZE startchar = pcre2_get_startchar(match_data->match_data);
  moonbit_decref(match_data);
  return startchar;
}

int32_t
moonbit_pcre2_match(
  moonbit_pcre2_code *code,
  moonbit_string_t subject,
  PCRE2_SIZE length,
  PCRE2_SIZE start_offset,
  uint32_t options,
  moonbit_pcre2_match_data *match_data,
  pcre2_match_context *match_context
) {
  int32_t captures = pcre2_match(
    code->code, subject, length, start_offset, options, match_data->match_data,
    match_context
  );
  moonbit_decref(code);
  moonbit_decref(subject);
  moonbit_decref(match_data);
  return captures;
}

int32_t
moonbit_pcre2_pattern_info_uint32(
  moonbit_pcre2_code *code,
  uint32_t what,
  uint32_t *where
) {
  int32_t result = pcre2_pattern_info(code->code, what, where);
  moonbit_decref(code);
  moonbit_decref(where);
  return result;
}

int32_t
moonbit_pcre2_pattern_info_uint16_pointer(
  moonbit_pcre2_code *code,
  uint32_t what,
  uint16_t **where
) {
  int32_t result = pcre2_pattern_info(code->code, what, where);
  moonbit_decref(code);
  moonbit_decref(where);
  return result;
}
