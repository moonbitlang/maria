///|
pub(all) enum Status {
  Idle
  Busy
}

///|
pub impl ToJson for Status with fn to_json(self) {
  match self {
    Idle => "idle"
    Busy => "generating"
  }
}

///|
pub impl @json.FromJson for Status with fn from_json(json, path) {
  guard json is String(s) else {
    raise @json.JsonDecodeError(
      (
        path, "@moonbitlang/maria/cmd/server.Status::from_json: expected string representation",
      ),
    )
  }
  match s.to_lower() {
    "idle" => Idle
    "generating" => Busy
    _ =>
      raise @json.JsonDecodeError(
        (
          path,
          "@moonbitlang/maria/cmd/server.Status::from_json: unknown status '\{s}'",
        ),
      )
  }
}

///|
test "Status::ToJson" {
  json_inspect(Idle, content="idle")
  json_inspect(Busy, content="generating")
}

///|
test "Status::FromJson" {
  json_inspect(@json.from_json("idle") is Idle, content=true)
  json_inspect(@json.from_json("generating") is Busy, content=true)
}

///|
pub extend Status with ToJson::{to_json}

///|
pub extend Status with @moonbitlang/core/json.FromJson::{from_json}
