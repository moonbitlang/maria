///|
/// Comparison operator for a filter.
pub enum ComparisonFilterType {
  Eq
  Ne
  Gt
  Gte
  Lt
  Lte
}

///|
pub impl ToJson for ComparisonFilterType with to_json(
  self : ComparisonFilterType,
) -> Json {
  match self {
    Eq => "eq"
    Ne => "ne"
    Gt => "gt"
    Gte => "gte"
    Lt => "lt"
    Lte => "lte"
  }
}

///|
pub impl @json.FromJson for ComparisonFilterType with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ComparisonFilterType raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError((path, "ComparisonFilterType: expected string"))
  }
  match value {
    "eq" => Eq
    "ne" => Ne
    "gt" => Gt
    "gte" => Gte
    "lt" => Lt
    "lte" => Lte
    _ =>
      raise @json.JsonDecodeError(
        (path, "ComparisonFilterType: invalid value '\{value}'"),
      )
  }
}

///|
/// A filter used to compare a specified attribute key to a given value.
pub struct ComparisonFilter {
  key : String
  type_ : ComparisonFilterType
  value : ComparisonFilterValue
}

///|
pub impl ToJson for ComparisonFilter with to_json(self : ComparisonFilter) -> Json {
  { "key": self.key, "type": self.type_, "value": self.value }
}

///|
pub impl @json.FromJson for ComparisonFilter with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ComparisonFilter raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let key : String = object.required("key", path~)
  let type_ : ComparisonFilterType = object.required("type", path~)
  let value : ComparisonFilterValue = object.required("value", path~)
  ComparisonFilter::{ key, type_, value }
}

///|
/// Union for comparison filter values.
pub enum ComparisonFilterValue {
  String(String)
  Float(Double)
  Bool(Bool)
  Array(Array[ComparisonFilterValueArrayItemUnion])
}

///|
pub impl ToJson for ComparisonFilterValue with to_json(
  self : ComparisonFilterValue,
) -> Json {
  match self {
    String(value) => value.to_json()
    Float(value) => value.to_json()
    Bool(value) => value.to_json()
    Array(value) => value.to_json()
  }
}

///|
pub impl @json.FromJson for ComparisonFilterValue with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ComparisonFilterValue raise @json.JsonDecodeError {
  match json {
    String(value) => String(value)
    Number(value, ..) => Float(value)
    True => Bool(true)
    False => Bool(false)
    Array(values) => {
      let items : Array[ComparisonFilterValueArrayItemUnion] = []
      for index, item in values {
        items.push(@json.from_json(item, path=path.add_index(index)))
      }
      Array(items)
    }
    _ =>
      raise @json.JsonDecodeError(
        (path, "ComparisonFilterValueUnion: invalid value"),
      )
  }
}

///|
/// Array items for comparison filter values.
pub enum ComparisonFilterValueArrayItemUnion {
  String(String)
  Float(Double)
}

///|
pub impl ToJson for ComparisonFilterValueArrayItemUnion with to_json(
  self : ComparisonFilterValueArrayItemUnion,
) -> Json {
  match self {
    String(value) => value.to_json()
    Float(value) => value.to_json()
  }
}

///|
pub impl @json.FromJson for ComparisonFilterValueArrayItemUnion with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ComparisonFilterValueArrayItemUnion raise @json.JsonDecodeError {
  match json {
    String(value) => String(value)
    Number(value, ..) => Float(value)
    _ =>
      raise @json.JsonDecodeError(
        (path, "ComparisonFilterValueArrayItemUnion: invalid value"),
      )
  }
}
