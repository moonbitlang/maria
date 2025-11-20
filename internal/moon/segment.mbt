///|
priv struct Segment {
  offset : Int
  length : Int
  diagnostics : @diagnostics.Diagnostics
} derive(Show)

///|
fn Segment::new(offset~ : Int, length~ : Int) -> Segment {
  Segment::{ offset, length, diagnostics: @diagnostics.Diagnostics::new() }
}

///|
impl ToJson for Segment with to_json(self : Segment) -> Json {
  {
    "start": self.offset,
    "end": self.offset + self.length,
    "diagnostics": self.diagnostics,
  }
}

///|
struct SegmentView {
  file : File
  index : Int
}

///|
pub fn SegmentView::content(self : SegmentView) -> String {
  let segment = self.file.segments[self.index]
  self.file.lines[segment.offset:segment.offset + segment.length].join("\n")
}

///|
pub impl ToJson for SegmentView with to_json(self : SegmentView) -> Json {
  { "file": self.file.path, "index": self.index, "content": self.content() }
}

///|
pub fn SegmentView::diagnostics(self : SegmentView) -> @diagnostics.Diagnostics {
  self.file.segments[self.index].diagnostics
}

///|
/// Calculates the **full file content** after replacing the segment with new
/// content.
pub fn SegmentView::replace(self : SegmentView, content : String) -> String {
  self.file.replace_segment(self.index, content)
}
