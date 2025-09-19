///|
fn @bytes.View::end_offset(self : @bytes.View) -> Int {
  self.start_offset() + self.length()
}

///|
pub let sep : Byte = try {
  if @uv.os_uname().sysname() == "Windows_NT" {
    '\\'
  } else {
    '/'
  }
} catch {
  error => {
    let message = @encoding/utf8.decode_lossy(error.to_bytes())
    println(
      "Warning: failed to set default path implementation, defaulting to posix. Error: \{message}",
    )
    '/'
  }
}

///|
pub fn dirname(path : @bytes.View) -> @bytes.View {
  if sep == '\\' {
    loop path {
      [] => "."
      [.. view, '\\' | '/'] => return view
      [.. view, _] => continue view
    }
  } else {
    loop path {
      [] => "."
      [.. view, '/'] => return view
      [.. view, _] => continue view
    }
  }
}

///|
pub fn basename(path : @bytes.View) -> @bytes.View {
  if sep == '\\' {
    loop path[:] {
      [] => "."
      [.., '\\' | '/'] as view => path[view.end_offset():]
      [.. view, _] => continue view
    }
  } else {
    loop path[:] {
      [] => "."
      [.., '/'] as view => path[view.end_offset():]
      [.. view, _] => continue view
    }
  }
}

///|
pub fn ext(path : @bytes.View) -> @bytes.View {
  loop path[:] {
    [] => ""
    [.. view, '.'] => path[view.end_offset():]
    [.. view, _] => continue view
  }
}

///|
pub fn stem(path : @bytes.View) -> @bytes.View {
  let base = basename(path)
  loop base[:] {
    [] => base
    [.. view, '.'] => view
    [.. view, _] => continue view
  }
}

///|
fn trim_sep(p : @bytes.View) -> @bytes.View {
  if sep == '\\' {
    loop p {
      [.. p, '\\' | '/'] => continue p
      _ => break
    }
  } else {
    loop p {
      [.. p, '/'] => continue p
      _ => break
    }
  }
  return p
}

///|
pub fn join(p : @bytes.View, q : @bytes.View) -> Bytes {
  let p = trim_sep(p)
  let q = trim_sep(q)
  if p is ("" | ".") {
    return q.to_bytes()
  }
  if q is ("" | ".") {
    return p.to_bytes()
  }
  let buffer = @buffer.new()
  buffer.write_bytesview(p)
  buffer.write_byte(sep)
  buffer.write_bytesview(q)
  buffer.to_bytes()
}
