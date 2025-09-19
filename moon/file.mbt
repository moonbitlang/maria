///|
struct File {
  path : String
  mut content : String
  mut lines : Array[StringView]
  segments : Array[Segment]
  mut mtime : Int64
}

///|
pub fn File::path(self : File) -> String {
  self.path
}

///|
pub impl ToJson for File with to_json(self : File) -> Json {
  {
    "content": self.content,
    "header": self.header(),
    "segments": self.segments(),
    "diagnostics": self.diagnostics().collect(),
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
      self.segments.push(
        Segment::new(
          self,
          offset~,
          length=i - offset,
          index=self.segments.length() + 1,
        ),
      )
      offset = i
    }
  }
  if offset < self.lines.length() {
    self.segments.push(
      Segment::new(
        self,
        offset~,
        length=self.lines.length() - offset,
        index=self.segments.length() + 1,
      ),
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
pub fn File::header(self : File) -> Segment {
  self.segments[0]
}

///|
pub fn File::segments(self : File) -> ArrayView[Segment] {
  self.segments[1:]
}

///|
pub fn File::segment(self : File, index : Int) -> Segment {
  self.segments[index + 1]
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
fn File::diagnostics(self : File) -> Iter[Diagnostic] {
  let mut diagnostics = Iter::empty()
  for segment in self.segments {
    diagnostics = diagnostics.concat(segment.diagnostics.iter())
  }
  diagnostics
}

///|
fn File::add_diagnostic(self : File, diagnostic : Diagnostic) -> Unit {
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
async fn File::replace_segment(
  self : File,
  index : Int,
  content : String,
) -> Unit {
  let replaced = StringBuilder::new()
  for i in 0..<self.lines.length() {
    if i == self.segments[index].offset {
      replaced.write_string(content)
      replaced.write_string("\n")
      continue i + self.segments[index].length - 1
    } else {
      let line = self.lines[i]
      replaced.write_substring(line.data(), line.start_offset(), line.length())
      replaced.write_string("\n")
    }
  }
  let replaced = replaced.to_string()
  @fs.write_to_file(self.path, replaced)
  self.parse(replaced)
  self.mtime = @fs.stat(self.path).mtime()
}
