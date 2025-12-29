///|
struct ResponseOutputTextAnnotationFileCitationParam {
  /// The ID of the file.
  file_id : String
  /// The filename of the file cited.
  filename : String
  /// The index of the file in the list of files.
  index : Int64
}

///|
pub impl ToJson for ResponseOutputTextAnnotationFileCitationParam with to_json(
  self : ResponseOutputTextAnnotationFileCitationParam,
) -> Json {
  {
    "type": "file_citation",
    "file_id": self.file_id,
    "filename": self.filename,
    "index": @jsonx.int64(self.index),
  }
}

///|
pub impl @json.FromJson for ResponseOutputTextAnnotationFileCitationParam with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputTextAnnotationFileCitationParam raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let file_id : String = object.required("file_id", path~)
  let filename : String = object.required("filename", path~)
  let index_json : Json = object.required("index", path~)
  let index : Int64 = match index_json {
    Number(index, repr=None) => index.to_int64()
    Number(_, repr=Some(index_str)) =>
      @strconv.parse_int64(index_str) catch {
        error =>
          raise @json.JsonDecodeError(
            (
              path.add_key("index"),
              "ResponseOutputTextAnnotationFileCitationParam: invalid 'index' field: \{error}",
            ),
          )
      }
    _ =>
      raise @json.JsonDecodeError(
        (
          path.add_key("index"),
          "ResponseOutputTextAnnotationFileCitationParam: expected number for 'index' field",
        ),
      )
  }
  ResponseOutputTextAnnotationFileCitationParam::{ file_id, filename, index }
}
