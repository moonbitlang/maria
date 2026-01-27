///|
enum ResponseOutputTextAnnotationParam {
  FileCitation(ResponseOutputTextAnnotationFileCitationParam)
  UrlCitation(ResponseOutputTextAnnotationUrlCitationParam)
  ContainerFileCitation(ResponseOutputTextAnnotationContainerFileCitationParam)
  FilePath(ResponseOutputTextAnnotationFilePathParam)
}

///|
pub impl ToJson for ResponseOutputTextAnnotationParam with to_json(
  self : ResponseOutputTextAnnotationParam,
) -> Json {
  match self {
    FileCitation(param) => param.to_json()
    UrlCitation(param) => param.to_json()
    ContainerFileCitation(param) => param.to_json()
    FilePath(param) => param.to_json()
  }
}

///|
pub impl @json.FromJson for ResponseOutputTextAnnotationParam with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputTextAnnotationParam raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_str : String = object.required("type", path~)
  match type_str {
    "file_citation" => {
      let param = @json.from_json(json, path~)
      FileCitation(param)
    }
    "url_citation" => {
      let param = @json.from_json(json, path~)
      UrlCitation(param)
    }
    "container_file_citation" => {
      let param = @json.from_json(json, path~)
      ContainerFileCitation(param)
    }
    "file_path" => {
      let param = @json.from_json(json, path~)
      FilePath(param)
    }
    _ =>
      raise @json.JsonDecodeError(
        (
          path.add_key("type"),
          "ResponseOutputTextAnnotationParam: invalid type '\{type_str}'",
        ),
      )
  }
}
