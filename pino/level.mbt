///|
pub(all) enum Level {
  Trace
  Debug
  Info
  Warn
  Error
  Fatal
} derive(Show)

///|
fn Level::to_int(self : Level) -> Int {
  match self {
    Trace => 10
    Debug => 20
    Info => 30
    Warn => 40
    Error => 50
    Fatal => 60
  }
}
