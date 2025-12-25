///|
pub struct OpenAI {
  chat : ChatService
}

///|
pub fn OpenAI::new(base_url? : String = BaseUrl, api_key~ : String) -> OpenAI {
  let client = Client::new(base_url~, api_key~)
  OpenAI::{ chat: ChatService::new(client) }
}
