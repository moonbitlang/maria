///|
/// Unconstrained free-form text input format.
pub struct CustomToolInputFormatText {
  type_ : String
}

///|
pub impl ToJson for CustomToolInputFormatText with to_json(
  self : CustomToolInputFormatText,
) -> Json {
  { "type": self.type_ }
}

///|
pub impl @json.FromJson for CustomToolInputFormatText with from_json(
  json : Json,
  path : @json.JsonPath,
) -> CustomToolInputFormatText raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_ : String = object.required("type", path~)
  CustomToolInputFormatText::{ type_, }
}

///|
/// A grammar defined by the user.
pub struct CustomToolInputFormatGrammar {
  definition : String
  syntax : String
  type_ : String
}

///|
pub impl ToJson for CustomToolInputFormatGrammar with to_json(
  self : CustomToolInputFormatGrammar,
) -> Json {
  { "type": self.type_, "definition": self.definition, "syntax": self.syntax }
}

///|
pub impl @json.FromJson for CustomToolInputFormatGrammar with from_json(
  json : Json,
  path : @json.JsonPath,
) -> CustomToolInputFormatGrammar raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let definition : String = object.required("definition", path~)
  let syntax : String = object.required("syntax", path~)
  let type_ : String = object.required("type", path~)
  CustomToolInputFormatGrammar::{ definition, syntax, type_ }
}

///|
pub enum CustomToolInputFormatUnion {
  Text(CustomToolInputFormatText)
  Grammar(CustomToolInputFormatGrammar)
}

///|
pub impl ToJson for CustomToolInputFormatUnion with to_json(
  self : CustomToolInputFormatUnion,
) -> Json {
  match self {
    Text(value) => value.to_json()
    Grammar(value) => value.to_json()
  }
}

///|
pub impl @json.FromJson for CustomToolInputFormatUnion with from_json(
  json : Json,
  path : @json.JsonPath,
) -> CustomToolInputFormatUnion raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_str : String = object.required("type", path~)
  match type_str {
    "text" => Text(@json.from_json(json, path~))
    "grammar" => Grammar(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (
          path.add_key("type"),
          "CustomToolInputFormatUnion: invalid type '\{type_str}'",
        ),
      )
  }
}
