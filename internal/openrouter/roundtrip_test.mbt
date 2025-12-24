///|
/// We cannot directly test for equality in this function, because otherwise,
/// we cannot annotate the type `T`.
fn[T : @json.FromJson] from_json_array(
  json_values : Array[Json],
) -> Array[T] raise @json.JsonDecodeError {
  let values = []
  for json_value in json_values {
    let value : T = @json.from_json(json_value)
    values.push(value)
  }
  values
}

///|
fn[T : ToJson] to_json_array(values : Array[T]) -> Array[Json] {
  let json_values = []
  for value in values {
    let json_value : Json = value.to_json()
    json_values.push(json_value)
  }
  json_values
}
