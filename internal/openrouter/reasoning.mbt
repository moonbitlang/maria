///|
struct Reasoning {
  effort : Effort?
  summary : ReasoningSummaryVerbosity?
}

///|
pub impl ToJson for Reasoning with to_json(self : Reasoning) -> Json {
  let object : Map[String, Json] = {}
  if self.effort is Some(effort) {
    object["effort"] = effort.to_json()
  }
  if self.summary is Some(summary) {
    object["summary"] = summary.to_json()
  }
  Json::object(object)
}

///|
pub impl @json.FromJson for Reasoning with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Reasoning raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.Reasoning::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let effort : Effort? = match object.get("effort") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("effort")))
  }
  let summary : ReasoningSummaryVerbosity? = match object.get("summary") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("summary")))
  }
  Reasoning::{ effort, summary }
}
