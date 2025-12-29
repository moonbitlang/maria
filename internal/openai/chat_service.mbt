///|
pub struct ChatService {
  completions : ChatCompletionService
}

///|
pub fn ChatService::new(base_url~ : String, api_key~ : String) -> ChatService {
  { completions: ChatCompletionService::new(base_url~, api_key~) }
}
