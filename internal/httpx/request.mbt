///|
pub struct RequestReader {
  body : &@io.Reader
  method_ : Method
  path : StringView
  vars : Map[StringView, StringView]
}

///|
pub impl @io.Reader for RequestReader with _get_internal_buffer(
  self : RequestReader,
) -> @io.ReaderBuffer {
  return self.body._get_internal_buffer()
}

///|
pub impl @io.Reader for RequestReader with _direct_read(
  self : RequestReader,
  buf : FixedArray[Byte],
  offset~ : Int,
  max_len~ : Int,
) -> Int {
  return self.body._direct_read(buf, offset~, max_len~)
}
