///|
pub(all) enum Level {
  Trace
  Debug
  Info
  Warn
  Error
  Fatal
} derive(Show, Eq, Compare, ToJson)

///|
test {
  assert_true(Trace < Debug)
  assert_true(Debug < Info)
  assert_true(Info < Warn)
  assert_true(Warn < Error)
  assert_true(Error < Fatal)
}
