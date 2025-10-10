///|
fn StringView::end_offset(self : StringView) -> Int {
  self.start_offset() + self.length()
}

///|
pub let sep : Char = '/'

///|
pub fn dirname(path : StringView) -> StringView {
  loop path {
    [] => "."
    "/" => "/"
    "//" => "//"
    "///" => "/"
    [.. view, '/'] =>
      skip~: loop view {
        "/" => "/"
        "//" => "//"
        "///" => "/"
        [.. view, '/'] => continue skip~ view
        view => view
      }
    [.. view, _] => continue view
  }
}

///|
pub fn basename(path : StringView) -> StringView {
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
  loop path.view() {
    [] => path
    [.. path, '.'] => path
    [.. path, _] => continue path
  }
}

///|
pub fn split(view : StringView) -> Iter[StringView] {
  Iter::new(each => {
    let view = match view {
      [.. "///", .. rest] =>
        match each("/") {
          IterContinue =>
            skip~: loop rest {
              ['/', .. rest] => continue skip~ rest
              rest => rest
            }
          IterEnd => return IterEnd
        }
      [.. "//", .. rest] =>
        match each("//") {
          IterContinue => rest
          IterEnd => return IterEnd
        }
      ['/', .. rest] =>
        match each("/") {
          IterContinue => rest
          IterEnd => return IterEnd
        }
      rest => rest
    }
    let mut last = view
    loop view {
      ['/', .. rest] as view => {
        let part = last
          .data()
          .view(start_offset=last.start, end_offset=view.start)
        match each(part) {
          IterContinue => {
            let rest = skip~: loop rest {
              ['/', .. rest] => continue skip~ rest
              rest => rest
            }
            last = rest
            continue rest
          }
          IterEnd => break IterEnd
        }
      }
      [_, .. rest] => continue rest
      [] => {
        if last.is_empty() {
          break IterContinue
        }
        match each(last) {
          IterContinue => break IterEnd
          IterEnd => break IterEnd
        }
      }
    }
  })
}

///|
fn join_parts(parts : Array[StringView]) -> String {
  guard parts is [part, .. parts] else { return "." }
  let path = StringBuilder::new()
  if part is ("/" | "//") {
    path.write_substring(part.data(), part.start_offset(), part.length())
    path.write_string(parts.join("/"))
  } else {
    path.write_substring(part.data(), part.start_offset(), part.length())
    for part in parts {
      path.write_char(sep)
      path.write_substring(part.data(), part.start_offset(), part.length())
    }
  }
  path.to_string()
}

///|
fn push_normalized_part(parts : Array[StringView], part : StringView) -> Unit {
  if part is ("" | ".") {
    return
  }
  if part is ".." {
    match parts {
      ["/"] | ["//"] | [] | [.., ".."] => parts.push("..")
      parts => ignore(parts.pop())
    }
    return
  }
  parts.push(part)
}

///|
pub fn normalize(view : StringView) -> String {
  let parts = []
  for part in split(view) {
    push_normalized_part(parts, part)
  }
  join_parts(parts)
}

///|
pub fn join(p : StringView, q : StringView) -> String {
  let p = normalize(p)
  let q = normalize(q)
  if p is "." {
    return q
  }
  if q is "." {
    return p
  }
  if is_absolute(q) {
    return q
  }
  let path = StringBuilder::new()
  path.write_string(p)
  path.write_char(sep)
  path.write_string(q)
  normalize(path.to_string())
}

///|
pub fn is_absolute(path : StringView) -> Bool {
  path.length() >= 1 && path[0] == '/'
}

///|
pub fn is_relative(path : StringView) -> Bool {
  !is_absolute(path)
}

///|
pub fn relative(from : StringView, to : StringView) -> String raise {
  let from = resolve(from)
  let to = resolve(to)
  if from == to {
    return "."
  }
  let from_parts = split(from).collect()
  let to_parts = split(to).collect()
  let mut i = 0
  while i < from_parts.length() && i < to_parts.length() {
    if from_parts[i] != to_parts[i] {
      break
    }
    i += 1
  }
  let relative_parts : Array[StringView] = []
  for _ in i..<from_parts.length() {
    relative_parts.push("..")
  }
  for j in i..<to_parts.length() {
    push_normalized_part(relative_parts, to_parts[j])
  }
  join_parts(relative_parts)
}

///|
pub fn resolve(view : StringView) -> String raise {
  if is_absolute(view) {
    return normalize(view)
  } else {
    let cwd = @os.cwd()
    normalize(join(cwd, view))
  }
}
