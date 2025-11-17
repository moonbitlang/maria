///|
async fn publish(dry_run? : Bool = false, cwd? : StringView) -> Unit {
  let args : Array[StringView] = ["publish"]
  if dry_run is true {
    args.push("--dry-run")
  }
  let proc = @spawn.spawn("moon", args, cwd?)
  proc.check()
}

///|
pub async fn Module::publish(self : Module, dry_run? : Bool = false) -> Unit {
  publish(dry_run~, cwd=self.path)
}
