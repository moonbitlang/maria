///|
pub async fn[T] with_temporary_directory(
  template : String,
  f : async (String) -> T,
) -> T {
  let os_tmpdir = @encoding/utf8.decode(@uv.os_tmpdir())
  let template = @path.join(os_tmpdir, template)
  let tmpdir = @global.uv().fs_mkdtemp_sync(@encoding/utf8.encode(template))
  let tmpdir = @encoding/utf8.decode(tmpdir)
  try f(tmpdir) catch {
    error => raise error
  } noraise {
    value => value
  }
}
