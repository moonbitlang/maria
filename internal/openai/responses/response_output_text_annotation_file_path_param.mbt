///|
struct ResponseOutputTextAnnotationFilePathParam {
  /// The ID of the file.
  file_id : String
  /// The index of the file in the list of files.
  index : Int64
}

///|
pub impl ToJson for ResponseOutputTextAnnotationFilePathParam with to_json(
  self : ResponseOutputTextAnnotationFilePathParam,
) -> Json {
  {
    "type": "file_path",
    "file_id": self.file_id,
    "index": @jsonx.int64(self.index),
  }
}

///|
pub impl @json.FromJson for ResponseOutputTextAnnotationFilePathParam with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputTextAnnotationFilePathParam raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let file_id : String = object.required("file_id", path~)
  let index_json : Json = object.required("index", path~)
  let index : Int64 = match index_json {
    Number(index, repr=None) => index.to_int64()
    Number(_, repr=Some(index_repr)) =>
      @strconv.parse_int64(index_repr) catch {
        error =>
          raise @json.JsonDecodeError(
            (
              path.add_key("index"),
              "ResponseOutputTextAnnotationFilePathParam: invalid 'index' value '\{index_repr}': \{error}",
            ),
          )
      }
    _ =>
      raise @json.JsonDecodeError(
        (
          path.add_key("index"),
          "ResponseOutputTextAnnotationFilePathParam: expected number for 'index' field",
        ),
      )
  }
  ResponseOutputTextAnnotationFilePathParam::{ file_id, index }
}
