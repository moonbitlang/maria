///|
/// Unix timestamp represented as **milliseconds** since the Unix epoch (January
/// 1, 1970, 00:00:00 UTC).
struct Timestamp(Int64) derive(Eq)

///|
/// Creates a new timestamp from the given number of milliseconds since the Unix
/// epoch.
///
/// Parameters:
///
/// * `ms` : The number of milliseconds since January 1, 1970, 00:00:00 UTC.
///
/// Returns a `Timestamp` representing the given time.
pub fn Timestamp::from_ms(ms : Int64) -> Timestamp {
  Timestamp(ms)
}

///|
/// Converts the timestamp from milliseconds to seconds by truncating the
/// millisecond portion.
///
/// Parameters:
///
/// * `self` : The timestamp in milliseconds to convert.
///
/// Returns the number of seconds since the Unix epoch as an `Int64`, with the
/// millisecond portion truncated.
pub fn Timestamp::truncate_to_s(self : Timestamp) -> Int64 {
  self.0 / 1000
}

///|
/// Gets the millisecond value of this timestamp.
///
/// Parameters:
///
/// * `self` : The timestamp to extract the millisecond value from.
///
/// Returns the number of milliseconds since the Unix epoch (January 1, 1970,
/// 00:00:00 UTC) as an `Int64`.
pub fn Timestamp::ms(self : Timestamp) -> Int64 {
  self.0
}

///|
/// Calculates the difference in milliseconds between this timestamp and another
/// timestamp.
///
/// Parameters:
///
/// * `self` : The timestamp to subtract from.
/// * `other` : The timestamp to subtract.
///
/// Returns the difference in milliseconds as an `Int64`. A positive value
/// indicates that `self` is later than `other`, while a negative value
/// indicates that `self` is earlier than `other`.
pub fn Timestamp::ms_since(self : Timestamp, other : Timestamp) -> Int64 {
  self.0 - other.0
}

///|
pub impl ToJson for Timestamp with to_json(self : Timestamp) -> Json {
  Json::number(self.0.to_double(), repr=self.0.to_string())
}

///|
pub impl @json.FromJson for Timestamp with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Timestamp {
  match json {
    Number(num, repr=None) => {
      guard num >= 0.0 else {
        raise @json.JsonDecodeError(
          (json_path, "Timestamp::from_json: timestamp cannot be negative"),
        )
      }
      Timestamp(num.to_int64())
    }
    Number(_, repr=Some(num_str)) | String(num_str) =>
      Timestamp(
        @strconv.parse_int64(num_str) catch {
          error =>
            raise @json.JsonDecodeError(
              (
                json_path,
                "Timestamp::from_json: invalid UInt64 string: \{error}",
              ),
            )
        },
      )
    _ =>
      raise @json.JsonDecodeError(
        (json_path, "Timestamp::from_json: expected number"),
      )
  }
}
