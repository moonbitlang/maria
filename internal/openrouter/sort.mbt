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
