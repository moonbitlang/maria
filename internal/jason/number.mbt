///|
struct Number(String)

///|
/// Creates a `Number` from an integer value.
///
/// Parameters:
///
/// * `value` : The integer value to convert.
///
/// Returns a `Number` representing the given integer.
pub fn Number::from_int(value : Int) -> Number {
  return Number(value.to_string())
}

///|
/// Creates a new `Number` from an `Int64` value.
///
/// Parameters:
///
/// * `value` : The 64-bit integer value to convert.
///
/// Returns a `Number` representing the given integer value.
pub fn Number::from_int64(value : Int64) -> Number {
  return Number(value.to_string())
}

///|
/// Creates a `Number` from a double-precision floating-point value.
///
/// Parameters:
///
/// * `value` : The double-precision floating-point number to convert.
///
/// Returns a `Number` representing the given double value.
pub fn Number::from_double(value : Double) -> Number {
  return Number(value.to_string())
}

///|
/// Converts the `Number` to an `Int`.
///
/// Parameters:
///
/// * `self` : The `Number` to convert.
/// * `path` : The JSON path where this number is located, used for error
///   reporting. Defaults to `Root`.
///
/// Returns the integer value of the number.
///
/// Throws an error of type `InvalidNumber` if the number cannot be parsed as a
/// valid integer.
pub fn Number::to_int(
  self : Number,
  path? : JasonPath = Root,
) -> Int raise DecodeError {
  @strconv.parse_int(self.0) catch {
    error => raise DecodeError::InvalidNumber(path, error)
  }
}

///|
/// Converts the number to a 64-bit signed integer.
///
/// Parameters:
///
/// * `self` : The number to convert.
/// * `path` : The JSON path context for error reporting. Defaults to `Root` if
///   not provided.
///
/// Returns the 64-bit signed integer representation of the number.
///
/// Throws an error of type `InvalidNumber` if the number string cannot be
/// parsed as a valid 64-bit signed integer.
pub fn Number::to_int64(
  self : Number,
  path? : JasonPath = Root,
) -> Int64 raise DecodeError {
  @strconv.parse_int64(self.0) catch {
    error => raise DecodeError::InvalidNumber(path, error)
  }
}

///|
/// Converts the number to a `Double` value.
///
/// Parameters:
///
/// * `self` : The `Number` to convert.
/// * `path` : The JSON path context for error reporting (defaults to `Root`).
///
/// Returns the `Double` representation of the number.
///
/// Throws an error of type `InvalidNumber` if the number string cannot be
/// parsed as a valid `Double`.
pub fn Number::to_double(
  self : Number,
  path? : JasonPath = Root,
) -> Double raise DecodeError {
  @strconv.parse_double(self.0) catch {
    error => raise DecodeError::InvalidNumber(path, error)
  }
}
