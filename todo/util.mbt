///|
/// Get current ISO timestamp
fn get_current_timestamp(clock : &@clock.Clock) -> String raise {
  let ms = clock.now()
  let s = ms / 1000
  let ns = ms % 1000 * 1_000_000
  @time.unix(s, nanosecond=ns.to_int()).to_string()
}

///|
pub fn Priority::icon(self : Priority) -> String {
  match self {
    High => "🔴"
    Medium => "🟡"
    Low => "🟢"
  }
}

///|
pub fn Status::icon(self : Status) -> String {
  match self {
    Completed => "✅"
    InProgress => "🔄"
    Pending => "⏳"
  }
}
