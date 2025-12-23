///|
struct Epoch {}

///|
pub let epoch : Epoch = Epoch::{  }

///|
pub impl Clock for Epoch with now(_ : Epoch) -> Timestamp {
  Timestamp::from_ms(@async.now())
}

///|
pub impl Clock for Epoch with now_str(clock : Epoch) -> String {
  @time.unix(clock.now().truncate_to_s()).to_plain_date_time().to_string() catch {
    err => "Time error: \{err}"
  }
}

///|
pub(open) trait Clock {
  now(self : Self) -> Timestamp
  now_str(self : Self) -> String
}
