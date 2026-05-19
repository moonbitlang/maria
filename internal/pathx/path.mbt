///|
using @xpath {type Path}

///|
fn StringView::end_offset(self : StringView) -> Int {
  self.start_offset() + self.length()
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
  for v = path.view() {
    match v {
      [] => break path
      [.., '/'] as view => break path.view(start_offset=view.end_offset())
      [.. view, _] => continue view
    }
  }
}

///|
/// Extract extension name include `.`
///
/// property: `stem(path) + ext(path) == basename(path)`
fn ext(path : StringView) -> StringView {
  Path::extname(path.to_owned())
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
    "" => return path.to_owned()
    "." => return path.to_owned()
    ".." => return path.to_owned()
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
priv enum SplitState {
  Root
  Segment
}

///|
/// Split each path component, handle redundant slashes but doesn't resolve `.` and `..`.
pub fn split(view : StringView) -> Iter[StringView] {
  let mut state : SplitState = SplitState::Root
  let mut last = view
  Iter::new(() => {
    state~: for s = state {
      match s {
        Root =>
          match view {
            // More than 3 slashes are treated as single slash.
            [.. "///", .. rest] => {
              // Skip all redundant slashes.
              for r = rest {
                match r {
                  ['/', .. rest] => continue rest
                  rest => {
                    state = Segment
                    last = rest
                    break
                  }
                }
              }
              break state~ Some("/")
            }
            [.. "//", .. rest] => {
              state = Segment
              last = rest
              break state~ Some("//")
            }
            ['/', .. rest] => {
              state = Segment
              last = rest
              break state~ Some("/")
            }
            rest => {
              state = Segment
              last = rest
              continue state~ Segment
            }
          }
        Segment =>
          for v = last.view() {
            match v {
              ['/', .. rest] as view => {
                // Slice out the part before slash.
                let part = last
                  .data()
                  .view(
                    start_offset=last.start_offset(),
                    end_offset=view.start_offset(),
                  )
                // Skip redundant slashes.
                let rest = for r = rest {
                  match r {
                    ['/', .. rest] => continue rest
                    rest => break rest
                  }
                }
                last = rest
                break state~ Some(part)
              }
              [_, .. rest] => continue rest
              [] as view =>
                if last.is_empty() {
                  return None
                } else {
                  let part = last
                  last = view
                  break state~ Some(part)
                }
            }
          }
      }
    }
  })
}
