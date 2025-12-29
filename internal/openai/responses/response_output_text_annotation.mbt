///|
enum ResponseOutputTextAnnotation {
  FileCitation(ResponseOutputTextAnnotationFileCitation)
  UrlCitation(ResponseOutputTextAnnotationUrlCitation)
  ContainerFileCitation(ResponseOutputTextAnnotationContainerFileCitation)
  FilePath(ResponseOutputTextAnnotationFilePath)
}

///|
pub impl ToJson for ResponseOutputTextAnnotation with to_json(
  self : ResponseOutputTextAnnotation,
) -> Json {
  match self {
    FileCitation(annotation) => annotation.to_json()
    UrlCitation(annotation) => annotation.to_json()
    ContainerFileCitation(annotation) => annotation.to_json()
    FilePath(annotation) => annotation.to_json()
  }
}

///|
pub impl @json.FromJson for ResponseOutputTextAnnotation with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputTextAnnotation raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_str : String = object.required("type", path~)
  match type_str {
    "file_citation" => FileCitation(@json.from_json(json, path~))
    "url_citation" => UrlCitation(@json.from_json(json, path~))
    "container_file_citation" =>
      ContainerFileCitation(@json.from_json(json, path~))
    "file_path" => FilePath(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (
          path.add_key("type"),
          "ResponseOutputTextAnnotation: invalid type '\{type_str}'",
        ),
      )
  }
}
