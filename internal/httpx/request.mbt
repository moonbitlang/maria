///|
pub struct RequestReader {
  body : &@io.Reader
  method_ : Method
  path : StringView
  vars : Map[StringView, StringView]
}
