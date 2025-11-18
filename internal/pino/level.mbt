///|
/// Logging severity levels, ordered from least to most severe.
///
/// Levels are comparable, allowing for threshold-based filtering:
/// - Trace < Debug < Info < Warn < Error < Fatal
///
/// When a logger is configured with a minimum level, only messages at that
/// level or higher will be output.
///
/// Levels:
///
/// - `Trace`: Fine-grained diagnostic information for troubleshooting
/// - `Debug`: Detailed debugging information useful during development
/// - `Info`: General informational messages about application progress
/// - `Warn`: Warning messages for potentially problematic situations
/// - `Error`: Error messages for failures that don't stop the application
/// - `Fatal`: Critical errors that may cause application termination
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
