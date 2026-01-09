///|
/// Generic embedded asset representation.
pub(all) struct Asset {
  path : String
  content : String
} derive(Show, ToJson)

///|
/// Installs embedded assets into `root`, guarded by a marker fingerprint.
pub async fn install_assets(
  root : String,
  assets : Array[Asset],
  fingerprint : String,
  marker_filename : String,
  logger : @pino.Logger,
) -> Unit {
  if assets.is_empty() {
    return
  }
  let marker_path = @pathx.join(root, marker_filename)
  let marker_value = @fsx.read_file(marker_path) catch { _ => "" }
  if @fsx.exists(root) && marker_value.trim() == fingerprint {
    return
  }
  if @fsx.exists(root) {
    @fs.rmdir(root, recursive=true) catch {
      error =>
        logger.warn("Failed to remove assets directory '\{root}': \{error}")
    }
  }
  let mut created = true
  try @fsx.make_directory(root, recursive=true, exists_ok=true) catch {
    error => {
      logger.warn("Failed to create assets directory '\{root}': \{error}")
      created = false
    }
  } noraise {
    _ => ()
  }
  if !created {
    return
  }
  for asset in assets {
    if asset.path.is_empty() {
      continue
    }
    let dest = @pathx.join(root, asset.path)
    let parent = @pathx.dirname(dest).to_string()
    @fsx.make_directory(parent, recursive=true, exists_ok=true) catch {
      error => {
        logger.warn("Failed to create asset directory '\{parent}': \{error}")
        continue
      }
    }
    @fsx.write_to_file(dest, asset.content) catch {
      error => logger.warn("Failed to write asset '\{dest}': \{error}")
    }
  }
  @fsx.write_to_file(marker_path, fingerprint + "\n") catch {
    error =>
      logger.warn("Failed to write assets marker '\{marker_path}': \{error}")
  }
}
