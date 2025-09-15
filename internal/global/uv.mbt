///|
let g_uv : Result[@uv.Loop, @uv.Errno] = try? @uv.Loop::new()

///|
pub fn uv() -> @uv.Loop raise @uv.Errno {
  return g_uv.unwrap_or_error()
}
