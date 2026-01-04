///|
/// Find the root directory of the Git repository containing `path`.
///
/// This walks up the directory hierarchy and returns the first directory
/// containing a `.git` entry (either a directory or a file).
///
/// `path` can be either a directory path or a file path.
///
/// Returns `None` if `path` is not inside a Git repository.
pub async fn find_repo_root(path : StringView) -> String? {
  // Canonicalize first so that we don't accidentally loop due to `..` segments
  // or symlinks.
  let start = @fsx.resolve(path) catch { _ => return None }
  // `path` may point to a file; in that case we should start searching from its
  // containing directory.
  let start_dir : String = if @fsx.exists_as_file(start) {
    [..@pathx.dirname(start)]
  } else {
    start
  }
  loop start_dir {
    dir if (@fsx.exists(@pathx.join(dir, ".git")) catch { _ => false }) =>
      Some(dir)
    dir => {
      let parent : String = [..@pathx.dirname(dir)]
      // Reached filesystem root (dirname("/") == "/") or an unresolvable state.
      if parent == dir || parent == "." {
        None
      } else {
        continue parent
      }
    }
  }
}
