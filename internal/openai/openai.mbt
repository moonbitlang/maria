///|
pub struct OpenAI {
  chat : ChatService
  responses : @responses.ResponseService
}

///|
pub fn OpenAI::new(base_url~ : String, api_key~ : String) -> OpenAI {
  {
    chat: ChatService::new(base_url~, api_key~),
    responses: @responses.ResponseService::new(base_url~, api_key~),
  }
}
