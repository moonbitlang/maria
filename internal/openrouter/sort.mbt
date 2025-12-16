///|
enum Sort {
  Price
  Throughput
  Latency
}

///|
pub impl ToJson for Sort with to_json(self : Sort) -> Json {
  match self {
    Price => "price"
    Throughput => "throughput"
    Latency => "latency"
  }
}

///|
pub impl @json.FromJson for Sort with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Sort raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.Sort::from_json"
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect string"))
  }
  match s {
    "price" => Sort::Price
    "throughput" => Sort::Throughput
    "latency" => Sort::Latency
    _ =>
      raise @json.JsonDecodeError(
        (path, "\{func_name}: invalid value \"\{s}\""),
      )
  }
}
