///|
/// Detailed billing information for a request.
pub struct CostDetails {
  upstream_inference_cost : Double?
} derive(Show, ToJson)

///|
impl @json.FromJson for CostDetails with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> CostDetails {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  let upstream_inference_cost = match json.get("upstream_inference_cost") {
    Some(Null) => None
    Some(Number(upstream_inference_cost, ..)) => Some(upstream_inference_cost)
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path, "Expected 'upstream_inference_cost' to be a number"),
      )
    None => None
  }
  CostDetails::{ upstream_inference_cost, }
}
