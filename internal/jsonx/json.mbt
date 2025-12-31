///|
pub enum Jason {
  Null
  Bool(Bool)
  Number(Number)
  String(String)
  Object(Object)
  Array(Array[Jason])
}

///|
pub let null : Jason = Null

///|
pub fn Jason::bool(value : Bool) -> Jason {
  return Bool(value)
}

///|
pub fn Jason::number(number : Number) -> Jason {
  return Number(number)
}

///|
pub fn Jason::int(value : Int) -> Jason {
  return Number(Number::from_int(value))
}

///|
pub fn Jason::string(string : String) -> Jason {
  return String(string)
}

///|
pub fn Jason::object(object : Object) -> Jason {
  return Object(object)
}

///|
pub fn Jason::array(array : Array[Jason]) -> Jason {
  return Array(array)
}

///|
struct Number(String)

///|
pub fn Number::from_int(value : Int) -> Number {
  return Number(value.to_string())
}

///|
pub fn Number::from_int64(value : Int64) -> Number {
  return Number(value.to_string())
}

///|
pub fn Number::from_double(value : Double) -> Number {
  return Number(value.to_string())
}

///|
suberror JasonDecodeError {
  InvalidNumber(JasonPath, @strconv.StrConvError)
}

///|
pub fn Number::to_int(
  self : Number,
  path? : JasonPath = Root,
) -> Int raise JasonDecodeError {
  @strconv.parse_int(self.0) catch {
    error => raise JasonDecodeError::InvalidNumber(path, error)
  }
}

///|
pub fn Number::to_int64(
  self : Number,
  path? : JasonPath = Root,
) -> Int64 raise JasonDecodeError {
  @strconv.parse_int64(self.0) catch {
    error => raise JasonDecodeError::InvalidNumber(path, error)
  }
}

///|
pub fn Number::to_double(
  self : Number,
  path? : JasonPath = Root,
) -> Double raise JasonDecodeError {
  @strconv.parse_double(self.0) catch {
    error => raise JasonDecodeError::InvalidNumber(path, error)
  }
}

///|
enum JasonPath {
  Root
  Key(JasonPath, String)
  Index(JasonPath, Int)
}

///|
pub fn JasonPath::add_index(self : JasonPath, index : Int) -> JasonPath {
  Index(self, index)
}

///|
pub fn JasonPath::add_key(self : JasonPath, key : String) -> JasonPath {
  Key(self, key)
}
