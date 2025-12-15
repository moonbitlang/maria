///|
struct ChatGenerationParamsProvider {
  allow_fallbacks : Bool?
  require_parameters : Bool?
  data_collection : ChatGenerationParamsDataCollection?
  zdr : Bool?
  enforce_distillable_text : Bool?
  order : Array[Schema0]?
  only : Array[Schema0]?
  ignore : Array[Schema0]?
  quantizations : Array[Quantizations]?
  sort : Sort?
  max_price : ChatGenerationParamsMaxPrice?
  min_throughput : Float?
  max_latency : Float?
}

///|
pub impl ToJson for ChatGenerationParamsProvider with to_json(
  self : ChatGenerationParamsProvider,
) -> Json {
  let object : Map[String, Json] = {}
  if self.allow_fallbacks is Some(allow_fallbacks) {
    object["allow_fallbacks"] = allow_fallbacks.to_json()
  }
  if self.require_parameters is Some(require_parameters) {
    object["require_parameters"] = require_parameters.to_json()
  }
  if self.data_collection is Some(data_collection) {
    object["data_collection"] = data_collection.to_json()
  }
  if self.zdr is Some(zdr) {
    object["zdr"] = zdr.to_json()
  }
  if self.enforce_distillable_text is Some(enforce_distillable_text) {
    object["enforce_distillable_text"] = enforce_distillable_text.to_json()
  }
  if self.order is Some(order) {
    object["order"] = order.to_json()
  }
  if self.only is Some(only) {
    object["only"] = only.to_json()
  }
  if self.ignore is Some(ignore) {
    object["ignore"] = ignore.to_json()
  }
  if self.quantizations is Some(quantizations) {
    object["quantizations"] = quantizations.to_json()
  }
  if self.sort is Some(sort) {
    object["sort"] = sort.to_json()
  }
  if self.max_price is Some(max_price) {
    object["max_price"] = max_price.to_json()
  }
  if self.min_throughput is Some(min_throughput) {
    object["min_throughput"] = min_throughput.to_json()
  }
  if self.max_latency is Some(max_latency) {
    object["max_latency"] = max_latency.to_json()
  }
  Json::object(object)
}
