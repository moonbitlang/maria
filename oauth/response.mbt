///|
pub struct ResponsesRequest {
  model : String
  input : Array[InputItem]
  instructions : String
  stream : Bool?
  store : Bool?
} derive(Show)

///|
pub fn ResponsesRequest::new(
  model~ : String,
  input~ : Array[InputItem],
  instructions~ : String,
  stream? : Bool,
  store? : Bool,
) -> ResponsesRequest {
  { model, input, instructions, stream, store }
}

///|
pub impl ToJson for ResponsesRequest with to_json(self : ResponsesRequest) -> Json {
  let obj = {
    "model": self.model.to_json(),
    "input": self.input.to_json(),
    "instructions": self.instructions.to_json(),
  }
  if self.stream is Some(v) {
    obj["stream"] = v.to_json()
  }
  if self.store is Some(v) {
    obj["store"] = v.to_json()
  }
  Json::object(obj)
}
