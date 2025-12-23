///|
pub struct ResponsesRequest {
  model : String
  input : Array[ResponseInputItem]
  instructions : String
  tools : Array[Json]
  tool_choice : String
  stream : Bool?
  store : Bool?
} derive(Show)

///|
pub fn ResponsesRequest::new(
  model~ : String,
  input~ : Array[ResponseInputItem],
  instructions~ : String,
  tools? : Array[Json] = [],
  tool_choice? : String = "auto",
  stream? : Bool,
  store? : Bool,
) -> ResponsesRequest {
  { model, input, instructions, tools, tool_choice, stream, store }
}

///|
pub impl ToJson for ResponsesRequest with to_json(self : ResponsesRequest) -> Json {
  let obj = {
    "model": self.model.to_json(),
    "input": self.input.to_json(),
    "instructions": self.instructions.to_json(),
    "tools": self.tools.to_json(),
    "tool_choice": self.tool_choice.to_json(),
  }
  if self.stream is Some(v) {
    obj["stream"] = v.to_json()
  }
  if self.store is Some(v) {
    obj["store"] = v.to_json()
  }
  Json::object(obj)
}
