///|
/// A citation for a container file used to generate a model response.
///
/// The properties ContainerID, EndIndex, FileID, Filename, StartIndex, Type are
/// required.
struct ResponseOutputTextAnnotationContainerFileCitationParam {
  /// The ID of the container file.
  container_id : String
  /// The index of the last character of the container file citation in the
  /// message.
  end_index : Int64
  /// The ID of the file.
  file_id : String
  /// The index of the first character of the container file citation in the
  /// message.
  start_index : Int64
}

///|
pub impl ToJson for ResponseOutputTextAnnotationContainerFileCitationParam with to_json(
  self : ResponseOutputTextAnnotationContainerFileCitationParam,
) -> Json {
  {
    "type": "container_file_citation",
    "container_id": self.container_id,
    "start_index": @jsonx.int64(self.start_index),
    "end_index": @jsonx.int64(self.end_index),
    "file_id": self.file_id,
  }
}

///|
pub impl @json.FromJson for ResponseOutputTextAnnotationContainerFileCitationParam with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputTextAnnotationContainerFileCitationParam raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let container_id : String = object.required("container_id", path~)
  let end_index_json : Json = object.required("end_index", path~)
  let end_index : Int64 = match end_index_json {
    Number(end_index, repr=None) => end_index.to_int64()
    Number(_, repr=Some(end_index_repr)) =>
      @strconv.parse_int64(end_index_repr) catch {
        error =>
          raise @json.JsonDecodeError(
            (
              path.add_key("end_index"),
              "ResponseOutputTextAnnotationContainerFileCitationParam: invalid 'end_index' value '\{end_index_repr}': \{error}",
            ),
          )
      }
    _ =>
      raise @json.JsonDecodeError(
        (
          path.add_key("end_index"),
          "ResponseOutputTextAnnotationContainerFileCitationParam: expected 'end_index' to be a number",
        ),
      )
  }
  let file_id : String = object.required("file_id", path~)
  let start_index_json : Json = object.required("start_index", path~)
  let start_index : Int64 = match start_index_json {
    Number(start_index, repr=None) => start_index.to_int64()
    Number(_, repr=Some(start_index_repr)) =>
      @strconv.parse_int64(start_index_repr) catch {
        error =>
          raise @json.JsonDecodeError(
            (
              path.add_key("start_index"),
              "ResponseOutputTextAnnotationContainerFileCitationParam: invalid 'start_index' value '\{start_index_repr}': \{error}",
            ),
          )
      }
    _ =>
      raise @json.JsonDecodeError(
        (
          path.add_key("start_index"),
          "ResponseOutputTextAnnotationContainerFileCitationParam: expected 'start_index' to be a number",
        ),
      )
  }
  ResponseOutputTextAnnotationContainerFileCitationParam::{
    container_id,
    end_index,
    file_id,
    start_index,
  }
}
