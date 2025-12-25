///|
pub(all) enum ContentType {
  InputText
  OutputText
  Text
} derive(Show)

///|
pub impl ToJson for ContentType with to_json(self : ContentType) -> Json {
  match self {
    InputText => "input_text"
    OutputText => "output_text"
    Text => "text"
  }
}

///|
pub impl @json.FromJson for ContentType with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ContentType raise @json.JsonDecodeError {
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "ContentType: expected string"))
  }
  match s {
    "input_text" => InputText
    "output_text" => OutputText
    "text" => Text
    _ =>
      raise @json.JsonDecodeError((path, "ContentType: invalid value '\{s}'"))
  }
}

///|
pub struct ContentPart {
  type_ : ContentType
  text : String
} derive(Show)

///|
pub fn ContentPart::new(type_~ : ContentType, text~ : String) -> ContentPart {
  { type_, text }
}

///|
pub impl ToJson for ContentPart with to_json(self : ContentPart) -> Json {
  { "type": self.type_, "text": self.text }
}

///|
pub impl @json.FromJson for ContentPart with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ContentPart raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "ContentPart: expected object"))
  }
  let type_ : ContentType = match obj.get("type") {
    Some(v) => @json.from_json(v, path=path.add_key("type"))
    None => raise @json.JsonDecodeError((path, "ContentPart: missing 'type'"))
  }
  let text : String = match obj.get("text") {
    Some(String(s)) => s
    Some(_) =>
      raise @json.JsonDecodeError((path, "ContentPart: 'text' must be string"))
    None => raise @json.JsonDecodeError((path, "ContentPart: missing 'text'"))
  }
  { type_, text }
}

///|
pub struct InputItem {
  type_ : String
  role : Role
  content : Array[ContentPart]
} derive(Show)

///|
pub fn InputItem::new(
  type_~ : String,
  role~ : Role,
  content~ : Array[ContentPart],
) -> InputItem {
  { type_, role, content }
}

///|
pub impl ToJson for InputItem with to_json(self : InputItem) -> Json {
  { "type": self.type_, "role": self.role, "content": self.content }
}
