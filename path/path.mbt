///|
fn StringView::end_offset(self : StringView) -> Int {
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
pub fn dirname(path : StringView) -> StringView {
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
pub fn basename(path : StringView) -> StringView {
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
pub fn ext(path : StringView) -> StringView {
  loop path.view() {
    [] => ""
    [.. view, '.'] => path.view(start_offset=view.end_offset())
    [.. view, _] => continue view
  }
}

///|
pub fn stem(path : StringView) -> StringView {
  let base = basename(path)
  loop base.view() {
    [] => base
    [.. view, '.'] => view
    [.. view, _] => continue view
  }
}

///|
fn trim_sep(p : StringView) -> StringView {
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
pub fn join(p : StringView, q : StringView) -> StringView {
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
pub fn is_absolute(path : StringView) -> Bool {
  if sep == '\\' {
    path.length() >= 2 &&
    path[1] == ':' &&
    ((path[0] >= 'a' && path[0] <= 'z') || (path[0] >= 'A' && path[0] <= 'Z'))
  } else {
    path.length() >= 1 && path[0] == '/'
  }
}
