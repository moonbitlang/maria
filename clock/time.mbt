///|
struct Epoch {}

///|
pub let epoch : Epoch = Epoch::{ }

///|
pub impl Clock for Epoch with fn now(_ : Epoch) -> Timestamp {
  Timestamp::from_ms(@async.now())
}

///|
pub impl Clock for Epoch with fn now_str(clock : Epoch) -> String {
  @time.unix(clock.now().truncate_to_s()).to_plain_date_time().to_string() catch {
    err => "Time error: \{err}"
  }
}

///|
pub(open) trait Clock {
  fn now(self : Self) -> Timestamp
  fn now_str(self : Self) -> String
}

///|
pub extend Epoch with Clock::{now, now_str}
