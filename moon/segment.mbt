///|
struct Segment {
  file : File
  offset : Int
  length : Int
  index : Int
  diagnostics : Array[Diagnostic]
}

///|
fn Segment::new(
  file : File,
  index~ : Int,
  offset~ : Int,
  length~ : Int,
) -> Segment {
  Segment::{ file, offset, length, index, diagnostics: [] }
}

///|
pub fn Segment::lines(self : Segment) -> ArrayView[StringView] {
  self.file.lines[self.offset:self.offset + self.length]
}

///|
pub impl ToJson for Segment with to_json(self : Segment) -> Json {
  {
    "start": self.offset,
    "end": self.offset + self.length,
    "content": self.file.lines[self.offset:self.offset + self.length].join("\n"),
  }
}

///|
pub fn Segment::index(self : Segment) -> Int {
  self.index
}

///|
pub fn Segment::content(self : Segment) -> String {
  self.lines().join("\n")
}

///|
pub fn Segment::diagnostics(self : Segment) -> Array[Diagnostic] {
  self.diagnostics
}

///|
pub async fn Segment::replace(self : Segment, content : String) -> Unit {
  self.file.replace_segment(self.index, content)
}
