///|
struct Epoch {}

///|
pub let epoch : Epoch = Epoch::{  }

///|
pub impl Clock for Epoch with now(_ : Epoch) -> Int64 {
  @os.now_ms()
}

///|
pub(open) trait Clock {
  now(self : Self) -> Int64
}
