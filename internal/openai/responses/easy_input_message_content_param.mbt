///|
pub(all) enum EasyInputMessageContentParam {
  String(String)
  InputItemContentList(ResponseInputMessageContentListParam)
} derive(Show)

///|
pub impl ToJson for EasyInputMessageContentParam with to_json(
  self : EasyInputMessageContentParam,
) -> Json {
  match self {
    String(s) => s.to_json()
    InputItemContentList(list) => Json::array(list.map(item => item.to_json()))
  }
}

///|
pub impl @json.FromJson for EasyInputMessageContentParam with from_json(
  json : Json,
  path : @json.JsonPath,
) -> EasyInputMessageContentParam raise @json.JsonDecodeError {
  match json {
    String(s) => EasyInputMessageContentParam::String(s)
    Array(_) => {
      let list : ResponseInputMessageContentListParam = @json.from_json(
        json,
        path~,
      )
      EasyInputMessageContentParam::InputItemContentList(list)
    }
    _ =>
      raise @json.JsonDecodeError(
        (path, "EasyInputMessageContentParam: expected string or array"),
      )
  }
}

///|
trait ToEasyInputMessageContentParam {
  to_easy_input_message_content_param(Self) -> EasyInputMessageContentParam
}

///|
pub impl ToEasyInputMessageContentParam for String with to_easy_input_message_content_param(
  self : String,
) -> EasyInputMessageContentParam {
  EasyInputMessageContentParam::String(self)
}

///|
pub impl ToEasyInputMessageContentParam for ResponseInputMessageContentListParam with to_easy_input_message_content_param(
  self : ResponseInputMessageContentListParam,
) -> EasyInputMessageContentParam {
  EasyInputMessageContentParam::InputItemContentList(self)
}
