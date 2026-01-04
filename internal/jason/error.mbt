///|
pub suberror DecodeError {
  MissingField(JasonPath)
  TypeMismatch(JasonPath, expect~ : Array[JasonType], actual~ : Jason)
  InvalidNumber(JasonPath, @strconv.StrConvError)
}

///|
pub enum JasonType {
  Null
  Object
  Array
  String
  Number
  Bool
}
