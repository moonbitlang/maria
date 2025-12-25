///|
/// Aggregated usage information for a completion response.
pub struct CompletionUsage {
  completion_tokens : Int
  completion_tokens_details : CompletionTokensDetails?
  cost : Double?
  cost_details : CostDetails?
  prompt_tokens : Int
  prompt_tokens_details : PromptTokensDetails?
  total_tokens : Int
} derive(Show, ToJson)

///|
pub fn CompletionUsage::new(
  completion_tokens~ : Int,
  completion_tokens_details? : CompletionTokensDetails,
  cost? : Double,
  cost_details? : CostDetails,
  prompt_tokens~ : Int,
  prompt_tokens_details? : PromptTokensDetails,
  total_tokens~ : Int,
) -> CompletionUsage {
  {
    completion_tokens,
    completion_tokens_details,
    cost,
    cost_details,
    prompt_tokens,
    prompt_tokens_details,
    total_tokens,
  }
}

///|
pub impl @json.FromJson for CompletionUsage with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> CompletionUsage {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("completion_tokens") is Some(Number(completion_tokens, ..)) else {
    raise @json.JsonDecodeError(
      (json_path, "Missing 'completion_tokens' field"),
    )
  }
  let completion_tokens_details = match json.get("completion_tokens_details") {
    Some(Null) => None
    Some(details) => {
      let details : CompletionTokensDetails = @json.from_json(
        details,
        path=json_path.add_key("completion_tokens_details"),
      )
      Some(details)
    }
    None => None
  }
  let cost = match json.get("cost") {
    Some(Null) => None
    Some(Number(cost, ..)) => Some(cost)
    Some(_) =>
      raise @json.JsonDecodeError((json_path, "Expected 'cost' to be a number"))
    None => None
  }
  let cost_details = match json.get("cost_details") {
    Some(Null) => None
    Some(details) => {
      let details : CostDetails = @json.from_json(
        details,
        path=json_path.add_key("cost_details"),
      )
      Some(details)
    }
    None => None
  }
  guard json.get("prompt_tokens") is Some(Number(prompt_tokens, ..)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'prompt_tokens' field"))
  }
  let prompt_tokens_details = match json.get("prompt_tokens_details") {
    Some(Null) => None
    Some(details) => {
      let details : PromptTokensDetails = @json.from_json(
        details,
        path=json_path.add_key("prompt_tokens_details"),
      )
      Some(details)
    }
    None => None
  }
  guard json.get("total_tokens") is Some(Number(total_tokens, ..)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'total_tokens' field"))
  }
  CompletionUsage::{
    completion_tokens: completion_tokens.to_int(),
    completion_tokens_details,
    cost,
    cost_details,
    prompt_tokens: prompt_tokens.to_int(),
    prompt_tokens_details,
    total_tokens: total_tokens.to_int(),
  }
}
