///|
async test "with_temporary_directory" {
  let mut tmpdir = None
  @fsx.with_temporary_directory("mbt-XXXXXX", d => {
    tmpdir = Some(d)
    @json.inspect(@fsx.exists(d), content=true)
    @json.inspect(@fsx.kind(d) is Directory, content=true)
  })
  guard tmpdir is Some(d) else { fail("tmpdir is None") }
  @json.inspect(@fsx.exists(d), content=false)
}

///|
async test "mkdtemp" {
  let dir = @fsx.mkdtemp("mbt-XXXXXX")
  @json.inspect(@fsx.exists(dir), content=true)
  @json.inspect(@fsx.kind(dir) is Directory, content=true)
  @fs.rmdir(dir, recursive=true)
  @json.inspect(@fsx.exists(dir), content=false)
}
