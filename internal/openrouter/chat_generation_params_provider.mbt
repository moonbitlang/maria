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
