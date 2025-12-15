///|
enum Ttl {
  FiveMinutes
  OneHour
}

///|
pub impl ToJson for Ttl with to_json(self : Ttl) -> Json {
  match self {
    FiveMinutes => "5m"
    OneHour => "1h"
  }
}
