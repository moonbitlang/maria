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

///|
pub impl @json.FromJson for Ttl with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Ttl {
  let func_name = "\{PackageName}.Ttl::from_json"
  guard json is String(ttl_str) else {
    raise @json.JsonDecodeError((json_path, "\{func_name}: expect string"))
  }
  match ttl_str {
    "5m" => Ttl::FiveMinutes
    "1h" => Ttl::OneHour
    _ =>
      raise @json.JsonDecodeError(
        (json_path, "\{func_name}: invalid ttl '\{ttl_str}'"),
      )
  }
}
