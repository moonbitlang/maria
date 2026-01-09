///|
struct ResponseOutputTextAnnotationUrlCitationParam {
  /// The index of the last character of the URL citation in the message.
  end_index : Int64
  /// The index of the first character of the URL citation in the message.
  start_index : Int64
  /// The title of the web resource.
  title : String
  /// The URL of the web resource.
  url : String
}

///|
pub impl ToJson for ResponseOutputTextAnnotationUrlCitationParam with to_json(
  self : ResponseOutputTextAnnotationUrlCitationParam,
) -> Json {
  {
    "type": "url_citation",
    "start_index": @jsonx.int64(self.start_index),
    "end_index": @jsonx.int64(self.end_index),
    "title": self.title,
    "url": self.url,
  }
}

///|
pub impl @json.FromJson for ResponseOutputTextAnnotationUrlCitationParam with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputTextAnnotationUrlCitationParam raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let start_index_json : Json = object.required("start_index", path~)
  let start_index : Int64 = match start_index_json {
    Number(start_index, repr=None) => start_index.to_int64()
    Number(_, repr=Some(start_index_repr)) =>
      @strconv.parse_int64(start_index_repr) catch {
        error =>
          raise @json.JsonDecodeError(
            (
              path.add_key("start_index"),
              "ResponseOutputTextAnnotationUrlCitationParam: invalid 'start_index' value '\{start_index_repr}': \{error}",
            ),
          )
      }
    _ =>
      raise @json.JsonDecodeError(
        (
          path.add_key("start_index"),
          "ResponseOutputTextAnnotationUrlCitationParam: expected number",
        ),
      )
  }
  let end_index_json : Json = object.required("end_index", path~)
  let end_index : Int64 = match end_index_json {
    Number(end_index, repr=None) => end_index.to_int64()
    Number(_, repr=Some(end_index_repr)) =>
      @strconv.parse_int64(end_index_repr) catch {
        error =>
          raise @json.JsonDecodeError(
            (
              path.add_key("end_index"),
              "ResponseOutputTextAnnotationUrlCitationParam: invalid 'end_index' value '\{end_index_repr}': \{error}",
            ),
          )
      }
    _ =>
      raise @json.JsonDecodeError(
        (
          path.add_key("end_index"),
          "ResponseOutputTextAnnotationUrlCitationParam: expected number",
        ),
      )
  }
  let title : String = object.required("title", path~)
  let url : String = object.required("url", path~)
  ResponseOutputTextAnnotationUrlCitationParam::{
    end_index,
    start_index,
    title,
    url,
  }
}
