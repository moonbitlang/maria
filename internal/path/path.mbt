///|
using @xpath {type Path}

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
/// property: `stem(path) + "." + ext(path)`
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
/// property: `stem(path) + "." + ext(path)`
pub fn stem(path : StringView) -> StringView {
  loop path.view() {
    [] => path
    [.. path, '.'] => path
    [.. path, _] => continue path
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
  Path::is_absolute(path.to_string())
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
/// 
/// edge cases: when from is equal to to, return "."
pub fn relative(from : StringView, to : StringView) -> String raise {
  let result = Path::relative(to.to_string(), base=from.to_string()).0
  if result.is_empty() {
    "."
  } else {
    result
  }
}

///|
/// Resolve relative path to absolute path.
/// 
/// 1. if absolute path is given, normalize and return it.
/// 2. if relative path is given, join it with current working directory,
pub fn resolve(view : StringView) -> String raise {
  Path::resolve(view.to_string()).0
}
