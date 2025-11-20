///|
struct File {
  path : String
  mut content : String
  mut lines : Array[StringView]
  /// segment[0] is the header
  /// segment[1] is the first code segment, etc.
  segments : Array[Segment]
  mut mtime : Int64
} derive(Show)

///|
pub fn File::path(self : File) -> String {
  self.path
}

///|
pub impl ToJson for File with to_json(self : File) -> Json {
  {
    "content": self.content,
    "header": self.segments[0],
    "segments": self.segments[1:],
    "diagnostics": self.diagnostics(),
  }
}

///|
fn File::new(
  path : String,
  content? : String = "",
  lines? : Array[StringView] = [],
  segments? : Array[Segment] = [],
) -> File {
  File::{ path, content, lines, segments, mtime: 0 }
}

///|
async fn File::parse(self : File, content : String) -> Unit {
  self.content = content
  self.lines = self.content.split("\n").collect()
  self.segments.clear()
  let mut offset = 0
  for i in 0..<self.lines.length() {
    let line = self.lines[i]
    if line.has_prefix("///|") {
      self.segments.push(Segment::new(offset~, length=i - offset))
      offset = i
    }
  }
  if offset < self.lines.length() {
    self.segments.push(
      Segment::new(offset~, length=self.lines.length() - offset),
    )
  }
}

///|
async fn File::load(self : File) -> Unit {
  if self.mtime != 0 && self.mtime == @fsx.stat(self.path).mtime() {
    return
  }
  let content = @fsx.read_file(self.path)
  self.parse(content)
  self.mtime = @fsx.stat(self.path).mtime()
}

///|
pub fn File::header(self : File) -> SegmentView {
  SegmentView::{ file: self, index: 0 }
}

///|
pub fn File::segments(self : File) -> ArrayView[SegmentView] {
  let views = []
  for i in 1..<self.segments.length() {
    views.push(SegmentView::{ file: self, index: i })
  }
  views
}

///|
pub fn File::segment(self : File, index : Int) -> SegmentView {
  guard index >= 0 && index < self.segments.length() - 1 else {
    abort(
      "Segment index \{index} out of bounds [0, \{self.segments.length() - 1})",
    )
  }
  SegmentView::{ file: self, index: index + 1 }
}

///|
pub fn File::lines(self : File) -> Array[StringView] {
  self.lines
}

///|
fn File::clear_diagnostics(self : File) -> Unit {
  for segment in self.segments {
    segment.diagnostics.clear()
  }
}

///|
fn File::diagnostics(self : File) -> @diagnostics.Diagnostics {
  let diagnostics = @diagnostics.Diagnostics::new()
  for segment in self.segments {
    diagnostics.append(segment.diagnostics)
  }
  diagnostics
}

///|
fn File::add_diagnostic(
  self : File,
  diagnostic : @diagnostics.Diagnostic,
) -> Unit {
  guard diagnostic.loc.path == self.path else {
    abort("Diagnostic path does not match file path")
  }
  for segment in self.segments {
    if diagnostic.loc.start.line >= segment.offset + 1 &&
      diagnostic.loc.start.line <= segment.offset + segment.length {
      segment.diagnostics.push(diagnostic)
      return
    }
  }
}

///|
fn File::replace_segment(self : File, index : Int, content : String) -> String {
  let replaced = []
  for segment in self.segments[:index] {
    for i in 0..<segment.length {
      guard segment.offset + i >= 0 && segment.offset + i < self.lines.length() else {
        abort(
          "segment.offset + i (\{segment.offset + i}) out of bounds [0, \{self.lines.length()})",
        )
      }
      let line = self.lines[segment.offset + i]
      replaced.push(line)
    }
  }
  replaced.push(content)
  for segment in self.segments[index + 1:] {
    for i in 0..<segment.length {
      guard segment.offset + i >= 0 && segment.offset + i < self.lines.length() else {
        abort(
          "segment.offset + i (\{segment.offset + i}) out of bounds [0, \{self.lines.length()})",
        )
      }
      let line = self.lines[segment.offset + i]
      replaced.push(line)
    }
  }
  replaced.join("\n")
}

///|
pub async fn File::write(self : File, content : String) -> Unit {
  @fsx.write_to_file(self.path, content)
  self.parse(content)
  self.mtime = @fsx.stat(self.path).mtime()
}
