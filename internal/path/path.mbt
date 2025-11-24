///|
fn StringView::end_offset(self : StringView) -> Int {
  self.start_offset() + self.length()
}

///|
/// Path component separator
pub let sep : Char = '/'

///|
/// Return the directory name of path.
///
/// This behavior is similar to Python `os.path.dirname`, but inconsistent with Posix convention dirname command.
///
/// edge cases: when path is relative path without directory component, return "."
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
/// Return the basename of path
///
/// 1. first trim trailing `/` if not root `/`
/// 2. extract last component after last `/`
///
/// This behavior is consistent with Posix convention basename command, but inconsistent with Python `os.path.basename`
///
pub fn basename(path : StringView) -> StringView {
  let path = match path {
    [.. path, '/'] => path
    path => path
  }
  loop path.view() {
    [] => path
    [.., '/'] as view => path.view(start_offset=view.end_offset())
    [.. view, _] => continue view
  }
}

///|
/// Extract extension name exclude `.`
///
/// property: `stem(path) + ext(path) == path`
pub fn ext(path : StringView) -> StringView {
  loop path.view() {
    [] | [.., '/'] => ""
    [.. view, '.'] => path.view(start_offset=view.end_offset())
    [.. view, _] => continue view
  }
}

///|
/// Extract stem part exclude `.`
///
/// property: `stem(path) + ext(path) == path`
pub fn stem(path : StringView) -> StringView {
  let mut dot : StringView? = None
  loop path.view() {
    [] | [.., '/'] as view =>
      if dot is Some(dot) {
        path
        .data()
        .view(start_offset=view.start_offset(), end_offset=dot.end_offset())
      } else {
        path
        .data()
        .view(start_offset=view.start_offset(), end_offset=path.end_offset())
      }
    [.. view, '.'] => {
      dot = Some(view)
      continue view
    }
    [.. view, _] => continue view
  }
}

///|
/// Split each path component, handle redundant slashes but doesn't resolve `.` and `..`.
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
          .view(
            start_offset=last.start_offset(),
            end_offset=view.start_offset(),
          )
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
/// Normalize path by resolving `.` and `..` and eliminating redundant slashes.
pub fn normalize(view : StringView) -> String {
  let parts = []
  for part in split(view) {
    push_normalized_part(parts, part)
  }
  join_parts(parts)
}

///|
/// 1. normalize path.
/// 2. if rhs is absolute path, return rhs.
pub fn join(p : StringView, q : StringView) -> String {
  let p = normalize(p)
  let q = normalize(q)
  // confuse behvior.
  // Python' os.path.join doesn't has this behavior.
  if p is "." {
    return q
  }
  if q is "." {
    return p
  }
  // Python's os.path.join behavior or Node.js `path.resolve` semantics.
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
/// Return relative path from `from` to `to`, `from` treated as current working directory.
///
/// property: `join(from, relative(from, to)) == resolve(to)`
///
/// join already normalizes the path, so no need to normalize here.
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
/// Resolve relative path to absolute path.
///
/// 1. if absolute path is given, normalize and return it.
/// 2. if relative path is given, join it with current working directory,
pub fn resolve(view : StringView) -> String raise {
  if is_absolute(view) {
    return normalize(view)
  } else {
    let cwd = @os.cwd()
    normalize(join(cwd, view))
  }
}
