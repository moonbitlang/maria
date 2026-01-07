///|
/// System skills installer.
///
/// System skills are embedded at build time and installed into
/// `~/.moonagent/skills/.system`. They are loaded with lower priority than
/// user/repo skills, so local skills can override by name.
const SYSTEM_SKILLS_DIR_NAME = ".system"

///|
const SYSTEM_SKILLS_MARKER_FILENAME = ".maria-system-skills.marker"

///|
fn system_skills_root(home : String) -> String {
  home
  |> @pathx.join(".moonagent")
  |> @pathx.join("skills")
  |> @pathx.join(SYSTEM_SKILLS_DIR_NAME)
}

///|
async fn install_system_skills(home : String, logger : @pino.Logger) -> Unit {
  let root = system_skills_root(home)
  @assets.install_assets(
    root,
    system_assets,
    system_assets_fingerprint,
    SYSTEM_SKILLS_MARKER_FILENAME,
    logger,
  )
}
