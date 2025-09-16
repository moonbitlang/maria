///|
fn @string.View::end_offset(self : @string.View) -> Int {
  self.start_offset() + self.length()
}

///|
pub let sep : Char = try {
  if @uv.os_uname().sysname() == "Windows_NT" {
    '\\'
  } else {
    '/'
  }
} catch {
  error => {
    let message = @utf8.decode_lossy(error.to_bytes())
    println(
      "Warning: failed to set default path implementation, defaulting to posix. Error: \{message}",
    )
    '/'
  }
}

///|
pub fn dirname(path : @string.View) -> @string.View {
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
pub fn basename(path : @string.View) -> @string.View {
  if sep == '\\' {
    let path = match path {
      [.. path, '\\' | '/'] => path
      path => path
    }
    loop path.view() {
      [] => "."
      [.., '\\' | '/'] as view => path.view(start_offset=view.end_offset())
      [.. view, _] => continue view
    }
  } else {
    let path = match path {
      [.. path, '/'] => path
      path => path
    }
    loop path.view() {
      [] => "."
      [.., '/'] as view => path.view(start_offset=view.end_offset())
      [.. view, _] => continue view
    }
  }
}

///|
pub fn ext(path : @string.View) -> @string.View {
  loop path.view() {
    [] => ""
    [.. view, '.'] => path.view(start_offset=view.end_offset())
    [.. view, _] => continue view
  }
}

///|
pub fn stem(path : @string.View) -> @string.View {
  let base = basename(path)
  loop base.view() {
    [] => base
    [.. view, '.'] => view
    [.. view, _] => continue view
  }
}

///|
fn trim_sep(p : @string.View) -> @string.View {
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
pub fn join(p : @string.View, q : @string.View) -> @string.View {
  let p = trim_sep(p)
  let q = trim_sep(q)
  if p is ("" | ".") {
    return q
  }
  if q is ("" | ".") {
    return p
  }
  let buffer = StringBuilder::new()
  buffer.write_substring(p.data(), p.start_offset(), p.length())
  buffer.write_char(sep)
  buffer.write_substring(q.data(), q.start_offset(), q.length())
  buffer.to_string()
}

///|
pub fn is_absolute(path : @string.View) -> Bool {
  if sep == '\\' {
    path.length() >= 2 &&
    path[1] == ':' &&
    ((path[0] >= 'a' && path[0] <= 'z') || (path[0] >= 'A' && path[0] <= 'Z'))
  } else {
    path.length() >= 1 && path[0] == '/'
  }
}
