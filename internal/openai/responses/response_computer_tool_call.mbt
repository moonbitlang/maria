///|
/// A call to the computer tool.
struct ResponseComputerToolCall {
  /// The unique ID of the computer call.
  id : String
  /// The action to perform.
  action : ResponseComputerToolCallAction
  /// An identifier used when responding to the tool call with output.
  call_id : String
  /// The pending safety checks for the computer call.
  pending_safety_checks : Array[ResponseComputerToolCallPendingSafetyCheck]
  /// The status of the item.
  status : ResponseComputerToolCallStatus
  /// The type of the computer call. Always `computer_call`.
  type_ : ResponseComputerToolCallType
}

///|
enum ResponseComputerToolCallAction {
  Click(ResponseComputerToolCallActionClick)
  DoubleClick(ResponseComputerToolCallActionDoubleClick)
  Drag(ResponseComputerToolCallActionDrag)
  Keypress(ResponseComputerToolCallActionKeypress)
  Move(ResponseComputerToolCallActionMove)
  Screenshot(ResponseComputerToolCallActionScreenshot)
  Scroll(ResponseComputerToolCallActionScroll)
  Type(ResponseComputerToolCallActionType)
  Wait(ResponseComputerToolCallActionWait)
}

///|
/// A click action.
struct ResponseComputerToolCallActionClick {
  /// Indicates which mouse button was pressed.
  button : String
  /// The x-coordinate where the click occurred.
  x : Int64
  /// The y-coordinate where the click occurred.
  y : Int64
}

///|
/// A double click action.
struct ResponseComputerToolCallActionDoubleClick {
  /// The x-coordinate where the double click occurred.
  x : Int64
  /// The y-coordinate where the double click occurred.
  y : Int64
}

///|
/// A drag action.
struct ResponseComputerToolCallActionDrag {
  /// An array of coordinates representing the path of the drag action.
  path : Array[ResponseComputerToolCallActionDragPath]
}

///|
/// An x/y coordinate pair.
struct ResponseComputerToolCallActionDragPath {
  /// The x-coordinate.
  x : Int64
  /// The y-coordinate.
  y : Int64
}

///|
/// A collection of keypresses the model would like to perform.
struct ResponseComputerToolCallActionKeypress {
  /// The combination of keys the model is requesting to be pressed.
  keys : Array[String]
}

///|
/// A mouse move action.
struct ResponseComputerToolCallActionMove {
  /// The x-coordinate to move to.
  x : Int64
  /// The y-coordinate to move to.
  y : Int64
}

///|
/// A screenshot action.
struct ResponseComputerToolCallActionScreenshot {}

///|
/// A scroll action.
struct ResponseComputerToolCallActionScroll {
  /// The horizontal scroll distance.
  scroll_x : Int64
  /// The vertical scroll distance.
  scroll_y : Int64
  /// The x-coordinate where the scroll occurred.
  x : Int64
  /// The y-coordinate where the scroll occurred.
  y : Int64
}

///|
/// An action to type in text.
struct ResponseComputerToolCallActionType {
  /// The text to type.
  text : String
}

///|
/// A wait action.
struct ResponseComputerToolCallActionWait {}

///|
/// A pending safety check for the computer call.
struct ResponseComputerToolCallPendingSafetyCheck {
  /// The ID of the pending safety check.
  id : String
  /// The type of the pending safety check.
  code : String?
  /// Details about the pending safety check.
  message : String?
}

///|
/// The status of the item.
enum ResponseComputerToolCallStatus {
  InProgress
  Completed
  Incomplete
}

///|
/// The type of the computer call.
enum ResponseComputerToolCallType {
  ComputerCall
}

///|
pub impl ToJson for ResponseComputerToolCallType with to_json(
  self : ResponseComputerToolCallType,
) -> Json {
  match self {
    ComputerCall => "computer_call"
  }
}

///|
pub impl @json.FromJson for ResponseComputerToolCallType with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseComputerToolCallType raise @json.JsonDecodeError {
  guard json is String(type_str) else {
    raise @json.JsonDecodeError(
      (path, "ResponseComputerToolCallType: expected string"),
    )
  }
  match type_str {
    "computer_call" => ComputerCall
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponseComputerToolCallType: invalid type '\{type_str}'"),
      )
  }
}

///|
pub impl ToJson for ResponseComputerToolCallStatus with to_json(
  self : ResponseComputerToolCallStatus,
) -> Json {
  match self {
    InProgress => "in_progress"
    Completed => "completed"
    Incomplete => "incomplete"
  }
}

///|
pub impl @json.FromJson for ResponseComputerToolCallStatus with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseComputerToolCallStatus raise @json.JsonDecodeError {
  guard json is String(status_str) else {
    raise @json.JsonDecodeError(
      (path, "ResponseComputerToolCallStatus: expected string"),
    )
  }
  match status_str {
    "in_progress" => InProgress
    "completed" => Completed
    "incomplete" => Incomplete
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponseComputerToolCallStatus: invalid status '\{status_str}'"),
      )
  }
}

///|
pub impl ToJson for ResponseComputerToolCallActionClick with to_json(
  self : ResponseComputerToolCallActionClick,
) -> Json {
  {
    "type": "click",
    "button": self.button,
    "x": @jsonx.int64(self.x),
    "y": @jsonx.int64(self.y),
  }
}

///|
pub impl @json.FromJson for ResponseComputerToolCallActionClick with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseComputerToolCallActionClick raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let button : String = object.required("button", path~)
  let _ : String = object.required("type", path~)
  let x = object.required_int64("x", path~)
  let y = object.required_int64("y", path~)
  ResponseComputerToolCallActionClick::{ button, x, y }
}

///|
pub impl ToJson for ResponseComputerToolCallActionDoubleClick with to_json(
  self : ResponseComputerToolCallActionDoubleClick,
) -> Json {
  {
    "type": "double_click",
    "x": @jsonx.int64(self.x),
    "y": @jsonx.int64(self.y),
  }
}

///|
pub impl @json.FromJson for ResponseComputerToolCallActionDoubleClick with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseComputerToolCallActionDoubleClick raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let _ : String = object.required("type", path~)
  let x = object.required_int64("x", path~)
  let y = object.required_int64("y", path~)
  ResponseComputerToolCallActionDoubleClick::{ x, y }
}

///|
pub impl ToJson for ResponseComputerToolCallActionDragPath with to_json(
  self : ResponseComputerToolCallActionDragPath,
) -> Json {
  { "x": @jsonx.int64(self.x), "y": @jsonx.int64(self.y) }
}

///|
pub impl @json.FromJson for ResponseComputerToolCallActionDragPath with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseComputerToolCallActionDragPath raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let x = object.required_int64("x", path~)
  let y = object.required_int64("y", path~)
  ResponseComputerToolCallActionDragPath::{ x, y }
}

///|
pub impl ToJson for ResponseComputerToolCallActionDrag with to_json(
  self : ResponseComputerToolCallActionDrag,
) -> Json {
  { "type": "drag", "path": self.path }
}

///|
pub impl @json.FromJson for ResponseComputerToolCallActionDrag with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseComputerToolCallActionDrag raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let path_value : Array[ResponseComputerToolCallActionDragPath] = object.required(
    "path",
    path~,
  )
  let _ : String = object.required("type", path~)
  ResponseComputerToolCallActionDrag::{ path: path_value }
}

///|
pub impl ToJson for ResponseComputerToolCallActionKeypress with to_json(
  self : ResponseComputerToolCallActionKeypress,
) -> Json {
  { "type": "keypress", "keys": self.keys }
}

///|
pub impl @json.FromJson for ResponseComputerToolCallActionKeypress with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseComputerToolCallActionKeypress raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let keys : Array[String] = object.required("keys", path~)
  let _ : String = object.required("type", path~)
  ResponseComputerToolCallActionKeypress::{ keys, }
}

///|
pub impl ToJson for ResponseComputerToolCallActionMove with to_json(
  self : ResponseComputerToolCallActionMove,
) -> Json {
  { "type": "move", "x": @jsonx.int64(self.x), "y": @jsonx.int64(self.y) }
}

///|
pub impl @json.FromJson for ResponseComputerToolCallActionMove with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseComputerToolCallActionMove raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let _ : String = object.required("type", path~)
  let x = object.required_int64("x", path~)
  let y = object.required_int64("y", path~)
  ResponseComputerToolCallActionMove::{ x, y }
}

///|
pub impl ToJson for ResponseComputerToolCallActionScreenshot with to_json(
  _ : ResponseComputerToolCallActionScreenshot,
) -> Json {
  { "type": "screenshot" }
}

///|
pub impl @json.FromJson for ResponseComputerToolCallActionScreenshot with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseComputerToolCallActionScreenshot raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let _ : String = object.required("type", path~)
  ResponseComputerToolCallActionScreenshot::{  }
}

///|
pub impl ToJson for ResponseComputerToolCallActionScroll with to_json(
  self : ResponseComputerToolCallActionScroll,
) -> Json {
  {
    "type": "scroll",
    "scroll_x": @jsonx.int64(self.scroll_x),
    "scroll_y": @jsonx.int64(self.scroll_y),
    "x": @jsonx.int64(self.x),
    "y": @jsonx.int64(self.y),
  }
}

///|
pub impl @json.FromJson for ResponseComputerToolCallActionScroll with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseComputerToolCallActionScroll raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let scroll_x = object.required_int64("scroll_x", path~)
  let scroll_y = object.required_int64("scroll_y", path~)
  let _ : String = object.required("type", path~)
  let x = object.required_int64("x", path~)
  let y = object.required_int64("y", path~)
  ResponseComputerToolCallActionScroll::{ scroll_x, scroll_y, x, y }
}

///|
pub impl ToJson for ResponseComputerToolCallActionType with to_json(
  self : ResponseComputerToolCallActionType,
) -> Json {
  { "type": "type", "text": self.text }
}

///|
pub impl @json.FromJson for ResponseComputerToolCallActionType with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseComputerToolCallActionType raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let text : String = object.required("text", path~)
  let _ : String = object.required("type", path~)
  ResponseComputerToolCallActionType::{ text, }
}

///|
pub impl ToJson for ResponseComputerToolCallActionWait with to_json(
  _ : ResponseComputerToolCallActionWait,
) -> Json {
  { "type": "wait" }
}

///|
pub impl @json.FromJson for ResponseComputerToolCallActionWait with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseComputerToolCallActionWait raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let _ : String = object.required("type", path~)
  ResponseComputerToolCallActionWait::{  }
}

///|
pub impl ToJson for ResponseComputerToolCallAction with to_json(
  self : ResponseComputerToolCallAction,
) -> Json {
  match self {
    Click(action) => action.to_json()
    DoubleClick(action) => action.to_json()
    Drag(action) => action.to_json()
    Keypress(action) => action.to_json()
    Move(action) => action.to_json()
    Screenshot(action) => action.to_json()
    Scroll(action) => action.to_json()
    Type(action) => action.to_json()
    Wait(action) => action.to_json()
  }
}

///|
pub impl @json.FromJson for ResponseComputerToolCallAction with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseComputerToolCallAction raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_str : String = object.required("type", path~)
  match type_str {
    "click" => Click(@json.from_json(json, path~))
    "double_click" => DoubleClick(@json.from_json(json, path~))
    "drag" => Drag(@json.from_json(json, path~))
    "keypress" => Keypress(@json.from_json(json, path~))
    "move" => Move(@json.from_json(json, path~))
    "screenshot" => Screenshot(@json.from_json(json, path~))
    "scroll" => Scroll(@json.from_json(json, path~))
    "type" => Type(@json.from_json(json, path~))
    "wait" => Wait(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (
          path.add_key("type"),
          "ResponseComputerToolCallAction: invalid type '\{type_str}'",
        ),
      )
  }
}

///|
pub impl ToJson for ResponseComputerToolCallPendingSafetyCheck with to_json(
  self : ResponseComputerToolCallPendingSafetyCheck,
) -> Json {
  let obj : Map[String, Json] = { "id": self.id }
  if self.code is Some(code) {
    obj["code"] = code.to_json()
  }
  if self.message is Some(message) {
    obj["message"] = message.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseComputerToolCallPendingSafetyCheck with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseComputerToolCallPendingSafetyCheck raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let id : String = object.required("id", path~)
  let code : String? = object.optional("code", path~)
  let message : String? = object.optional("message", path~)
  ResponseComputerToolCallPendingSafetyCheck::{ id, code, message }
}

///|
pub impl ToJson for ResponseComputerToolCall with to_json(
  self : ResponseComputerToolCall,
) -> Json {
  {
    "type": self.type_,
    "id": self.id,
    "action": self.action,
    "call_id": self.call_id,
    "pending_safety_checks": self.pending_safety_checks,
    "status": self.status,
  }
}

///|
pub impl @json.FromJson for ResponseComputerToolCall with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseComputerToolCall raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let id : String = object.required("id", path~)
  let action : ResponseComputerToolCallAction = object.required("action", path~)
  let call_id : String = object.required("call_id", path~)
  let pending_safety_checks : Array[ResponseComputerToolCallPendingSafetyCheck] = object.required(
    "pending_safety_checks",
    path~,
  )
  let status : ResponseComputerToolCallStatus = object.required("status", path~)
  let type_ : ResponseComputerToolCallType = object.required("type", path~)
  ResponseComputerToolCall::{
    id,
    action,
    call_id,
    pending_safety_checks,
    status,
    type_,
  }
}
