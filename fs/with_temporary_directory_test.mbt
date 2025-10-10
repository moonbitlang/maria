///|
async test "with_temporary_directory" {
  let mut tmpdir = None
  @this.with_temporary_directory("mbt-XXXXXX", d => {
    tmpdir = Some(d)
    @json.inspect(@this.exists(d), content=true)
    @json.inspect(@this.kind(d) is Directory, content=true)
  })
  guard tmpdir is Some(d) else { fail("tmpdir is None") }
  @json.inspect(@this.exists(d), content=false)
}
