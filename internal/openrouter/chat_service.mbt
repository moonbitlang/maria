///|
pub struct ChatService {
  completion : ChatCompletionService
}

///|
fn ChatService::new(client : Client) -> ChatService {
  ChatService::{ completion: ChatCompletionService::new(client) }
}
