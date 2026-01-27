///|
/// Compound filter operation type.
pub enum CompoundFilterType {
  And
  Or
}

///|
pub impl ToJson for CompoundFilterType with to_json(self : CompoundFilterType) -> Json {
  match self {
    And => "and"
    Or => "or"
  }
}

///|
pub impl @json.FromJson for CompoundFilterType with from_json(
  json : Json,
  path : @json.JsonPath,
) -> CompoundFilterType raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError((path, "CompoundFilterType: expected string"))
  }
  match value {
    "and" => And
    "or" => Or
    _ =>
      raise @json.JsonDecodeError(
        (path, "CompoundFilterType: invalid value '\{value}'"),
      )
  }
}

///|
/// Combine multiple filters using `and` or `or`.
pub struct CompoundFilter {
  filters : Array[ComparisonFilter]
  type_ : CompoundFilterType
}

///|
pub impl ToJson for CompoundFilter with to_json(self : CompoundFilter) -> Json {
  { "filters": self.filters, "type": self.type_ }
}

///|
pub impl @json.FromJson for CompoundFilter with from_json(
  json : Json,
  path : @json.JsonPath,
) -> CompoundFilter raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let filters : Array[ComparisonFilter] = object.required("filters", path~)
  let type_ : CompoundFilterType = object.required("type", path~)
  CompoundFilter::{ filters, type_ }
}
