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

///|
pub impl @json.FromJson for ChatGenerationParamsProvider with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatGenerationParamsProvider raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatGenerationParamsProvider::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let allow_fallbacks : Bool? = match object.get("allow_fallbacks") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("allow_fallbacks")))
  }
  let require_parameters : Bool? = match object.get("require_parameters") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("require_parameters")))
  }
  let data_collection : ChatGenerationParamsDataCollection? = match
    object.get("data_collection") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("data_collection")))
  }
  let zdr : Bool? = match object.get("zdr") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("zdr")))
  }
  let enforce_distillable_text : Bool? = match
    object.get("enforce_distillable_text") {
    None | Some(Null) => None
    Some(v) =>
      Some(@json.from_json(v, path=path.add_key("enforce_distillable_text")))
  }
  let order : Array[Schema0]? = match object.get("order") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("order")))
  }
  let only : Array[Schema0]? = match object.get("only") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("only")))
  }
  let ignore : Array[Schema0]? = match object.get("ignore") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("ignore")))
  }
  let quantizations : Array[Quantizations]? = match
    object.get("quantizations") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("quantizations")))
  }
  let sort : Sort? = match object.get("sort") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("sort")))
  }
  let max_price : ChatGenerationParamsMaxPrice? = match
    object.get("max_price") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("max_price")))
  }
  let min_throughput : Float? = match object.get("min_throughput") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("min_throughput")))
  }
  let max_latency : Float? = match object.get("max_latency") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("max_latency")))
  }
  ChatGenerationParamsProvider::{
    allow_fallbacks,
    require_parameters,
    data_collection,
    zdr,
    enforce_distillable_text,
    order,
    only,
    ignore,
    quantizations,
    sort,
    max_price,
    min_throughput,
    max_latency,
  }
}
