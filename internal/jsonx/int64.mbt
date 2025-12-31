///|
pub fn int64(value : Int64) -> Json {
  Json::number(value.to_double(), repr=value.to_string())
}
