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
