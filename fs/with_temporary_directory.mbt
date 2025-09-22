///|
pub async fn[T] with_temporary_directory(
  template : String,
  f : async (String) -> T,
) -> T {
  let os_tmpdir = @uv.os_tmpdir()
  let template = @path.join(os_tmpdir, @encoding/utf8.encode(template))
  let tmpdir = @global.uv().fs_mkdtemp_sync(template)
  f(@encoding/utf8.decode(tmpdir))
}
