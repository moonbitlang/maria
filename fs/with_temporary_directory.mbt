///|
pub async fn[T] with_temporary_directory(
  template : String,
  f : async (String) -> T raise,
) -> T raise {
  let os_tmpdir = @uv.os_tmpdir()
  let template = @path.join(os_tmpdir, @utf8.encode(template))
  let tmpdir = @global.uv().fs_mkdtemp_sync(template)
  f(@utf8.decode(tmpdir))
}
