///|
/// Helper wrapper around `@fs.File` for common read operations.
struct FileRead(@fs.File)

///|
/// Create a new file at `path` and return a `FileRead` handle.
///
/// The file is created with permission `0o644` and truncated if it
/// already exists.
pub async fn FileRead::create(path : StringView) -> FileRead {
  @fs.create(path.to_string(), permission=0o644)
}

///|
/// Close the underlying file descriptor.
pub fn FileRead::close(self : FileRead) -> Unit {
  self.0.close()
}

///|
/// Read the entire contents of the file as UTF-8 text.
pub async fn FileRead::read_text(self : FileRead) -> String {
  self.0.read_all().text()
}
