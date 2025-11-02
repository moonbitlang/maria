///|
struct File {
  path : String
  mut content : String
  mut lines : Array[StringView]
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
  if self.mtime != 0 && self.mtime == @fs.stat(self.path).mtime() {
    return
  }
  let content = @fs.read_file(self.path)
  self.parse(content)
  self.mtime = @fs.stat(self.path).mtime()
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
  SegmentView::{ file: self, index }
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
pub async fn File::replace_segment(
  self : File,
  index : Int,
  content : String,
) -> Unit {
  let replaced = StringBuilder::new()
  for segment in self.segments[:index + 1] {
    for i in 0..<segment.length {
      let line = self.lines[segment.offset + i]
      replaced.write_substring(line.data(), line.start_offset(), line.length())
      replaced.write_string("\n")
    }
  }
  replaced.write_string(content)
  replaced.write_string("\n")
  for segment in self.segments[index + 2:] {
    for i in 0..<segment.length {
      let line = self.lines[segment.offset + i]
      replaced.write_substring(line.data(), line.start_offset(), line.length())
      replaced.write_string("\n")
    }
  }
  let replaced = replaced.to_string()
  @fs.write_to_file(self.path, replaced)
  self.parse(replaced)
  self.mtime = @fs.stat(self.path).mtime()
}
