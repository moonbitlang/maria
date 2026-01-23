///|
pub impl @json.FromJson for Model with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Model {
  let object = @jsonx.as_object(json, path=json_path)
  let name : String = object.required("name", path=json_path)
  let model_name : String = object.required("model_name", path=json_path)
  let model_type : Type = object.required("model_type", path=json_path)
  let api_key : String = match object.get("api_key") {
    None => ""
    Some(api_key_json) =>
      @json.from_json(api_key_json, path=json_path.add_key("api_key"))
  }
  let base_url : String = match object.get("base_url") {
    Some(base_url_json) =>
      @json.from_json(base_url_json, path=json_path.add_key("base_url"))
    None =>
      match model_type {
        SaaS(OpenAI) => "https://api.openai.com/v1"
        SaaS(CodexOAuth) => "https://chatgpt.com/backend-api"
        SaaS(Copilot) => "https://api.githubcopilot.com"
      }
  }
  let description : String? = match object.get("description") {
    None => None
    Some(description_json) =>
      Some(
        @json.from_json(description_json, path=json_path.add_key("description")),
      )
  }
  let safe_zone_tokens : Int = match object.get("safe_zone_tokens") {
    None => 128_000
    Some(safe_zone_tokens_json) =>
      @json.from_json(
        safe_zone_tokens_json,
        path=json_path.add_key("safe_zone_tokens"),
      )
  }
  let supports_anthropic_prompt_caching : Bool = match
    object.get("supports_anthropic_prompt_caching") {
    None => false
    Some(supports_anthropic_prompt_caching_json) =>
      @json.from_json(
        supports_anthropic_prompt_caching_json,
        path=json_path.add_key("supports_anthropic_prompt_caching"),
      )
  }
  let supports_apply_patch : Bool = match object.get("supports_apply_patch") {
    Some(supports_apply_patch_json) =>
      @json.from_json(
        supports_apply_patch_json,
        path=json_path.add_key("supports_apply_patch"),
      )
    None => {
      // Auto-detect based on model name for GPT 5.1+
      let name_lower = model_name.to_lower()
      name_lower.contains("gpt-5.1") || name_lower.contains("gpt-5.2")
    }
  }
  let access_token : String? = match object.get("access_token") {
    None => None
    Some(access_token_json) =>
      Some(
        @json.from_json(
          access_token_json,
          path=json_path.add_key("access_token"),
        ),
      )
  }
  let account_id : String? = match object.get("account_id") {
    None => None
    Some(account_id_json) =>
      Some(
        @json.from_json(account_id_json, path=json_path.add_key("account_id")),
      )
  }
  let refresh_token : String? = match object.get("refresh_token") {
    None => None
    Some(refresh_token_json) =>
      Some(
        @json.from_json(
          refresh_token_json,
          path=json_path.add_key("refresh_token"),
        ),
      )
  }
  let id_token : String? = match object.get("id_token") {
    None => None
    Some(id_token_json) =>
      Some(@json.from_json(id_token_json, path=json_path.add_key("id_token")))
  }
  Model::{
    name,
    description,
    model_name,
    model_type,
    api_key,
    base_url,
    safe_zone_tokens,
    supports_anthropic_prompt_caching,
    supports_apply_patch,
    access_token,
    account_id,
    refresh_token,
    id_token,
  }
}

///|
pub impl @json.FromJson for Type with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Type {
  guard json is String(json) else {
    raise @json.JsonDecodeError(
      (json_path, "@moonbitlang/maria/model.Type::from_json: expected string"),
    )
  }
  match json {
    "saas/openai" => Type::SaaS(Provider::OpenAI)
    "saas/codex_oauth" => Type::SaaS(Provider::CodexOAuth)
    "saas/copilot" => Type::SaaS(Provider::Copilot)
    [.. "saas/", .. provider] =>
      raise @json.JsonDecodeError(
        (
          json_path,
          "@moonbitlang/maria/model.Type::from_json: unsupported SaaS provider '\{provider}'",
        ),
      )
    _ =>
      raise @json.JsonDecodeError(
        (
          json_path,
          "@moonbitlang/maria/model.Type::from_json: unknown model type '\{json}'",
        ),
      )
  }
}

///|
pub impl ToJson for Type with to_json(self) {
  match self {
    SaaS(OpenAI) => "saas/openai"
    SaaS(CodexOAuth) => "saas/codex_oauth"
    SaaS(Copilot) => "saas/copilot"
  }
}
