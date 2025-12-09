///|
/// Task state in the daemon system.
enum Task {
  /// Task is currently executing or idle. This means there is a corresponding
  /// HTTP server is running for this task.
  Running(Running)
  /// Task has been stopped or completed. This means there is no HTTP server
  /// associate with this task, and the task state is stored on disk.
  Stopped(Stopped)
}

///|
pub fn Task::is_idle(self : Task) -> Bool {
  match self {
    Running(running) => running.is_idle()
    Stopped(_) => false
  }
}

///|
pub impl ToJson for Task with to_json(self : Task) -> Json {
  match self {
    Running(running) => running.to_json()
    Stopped(stopped) => stopped.to_json()
  }
}

///|
pub impl @json.FromJson for Task with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Task raise @json.JsonDecodeError {
  guard json is { "status": type_, .. } else {
    raise @json.JsonDecodeError(
      (json_path, "Missing 'status' field in Task object"),
    )
  }
  match type_ {
    "generating" | "idle" => {
      let running : Running = @json.from_json(json, path=json_path)
      Task::Running(running)
    }
    "stopped" => {
      let stopped : Stopped = @json.from_json(
        json,
        path=json_path.add_key("stopped"),
      )
      Task::Stopped(stopped)
    }
    _ =>
      raise @json.JsonDecodeError(
        (json_path.add_key("status"), "Unknown Task status '\{type_}'"),
      )
  }
}
