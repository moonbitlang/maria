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
  let dir = @xpath.Path::dirname(path.to_string()).to_string()
  if dir.is_empty() {
    "."
  } else {
    dir
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
/// Extract extension name include `.`
/// 
/// property: `stem(path) + ext(path) == basename(path)`
pub fn ext(path : StringView) -> StringView {
  Path::extname(path.to_string())
}

///|
/// replace extension name with `ext`, if basename exists.
/// 
/// failed cases: 
///   1. if `basename(path)` is empty, return original path. 
///   2. if `basename(path)` is `.` or `..`, return original path.
/// 
/// This API is not consistent with Python `pathlib.Path.with_suffix`, which would raise exception in failed cases.
/// 
/// Justification:
/// 
/// when `replace_ext` fails, returning original path is logging friendly behavior,
/// by the way if `replace_ext` fails, user also hasn't good way to handle this error case.
/// 
/// for other purpose, if return original path LLM can re-try to diagnostic the issue.
/// 
pub fn replace_ext(path : StringView, ext : StringView) -> String {
  let basename = basename(path)
  match basename {
    "" => return path.to_string()
    "." => return path.to_string()
    ".." => return path.to_string()
    _ => {
      let old_ext_len = match basename.rev_find(".") {
        None => 0
        Some(idx) => basename.length() - idx
      }
      let directory_stem = path.view(
        start_offset=0,
        end_offset=path.length() - old_ext_len,
      )
      let buffer = StringBuilder::new(
        size_hint=(directory_stem.length() + ext.length()) << 1,
      )
      buffer.write_stringview(directory_stem)
      buffer.write_stringview(ext)
      buffer.to_string()
    }
  }
}

///|
/// Extract stem part exclude `.`
/// 
/// property: `stem(path) + ext(path) == basename(path)`
pub fn stem(path : StringView) -> StringView {
  let base = basename(path)
  let ext = ext(path)
  base.view(start_offset=0, end_offset=base.length() - ext.length())
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
/// Normalize path by resolving `.` and `..` and eliminating redundant slashes.
pub fn normalize(view : StringView) -> String {
  Path::normalize(view.to_string()).0
}

///|
/// 1. normalize path.
/// 2. if rhs is absolute path, return rhs.
pub fn join(p : StringView, q : StringView) -> String {
  Path::join(p.to_string(), q.to_string()).normalize().0
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
