///|
/// Task configuration and execution context for background processes.
struct Task {
  /// name for the task for identification purposes
  name : String?
  /// Unique identifier for the task
  id : @uuid.Uuid
  /// Current working directory where the task will be executed
  cwd : String
  /// Port number of the HTTP server the task is running on.
  port : Int
  /// Current execution status of the task
  mut status : @server.Status
  /// Array of queued message to be processed by the agent.
  queued_messages : Array[QueuedMessage]
  /// Timestamp indicating when the task was created, in milliseconds since epoch.
  created : @clock.Timestamp
  /// Whether the task has web search capabilities enabled.
  web_search : Bool
}

///|
/// Checks whether the task is currently in an idle state.
///
/// Parameters:
///
/// * `self` : The task to check the status of.
///
/// Returns `true` if the task is idle, `false` otherwise.
///
/// FIXME: This method is only used in tests.
pub fn Task::is_idle(self : Task) -> Bool {
  self.status is @server.Idle
}

///|
/// Creates a new task with the specified configuration parameters.
///
/// Parameters:
///
/// * `name` : Optional name for the task. If not provided, the task will have
///   no name.
/// * `id` : Unique identifier for the task.
/// * `cwd` : Current working directory where the task will be executed.
/// * `port` : Port number that the task will use for communication.
/// * `created` : Timestamp indicating when the task was created, typically in
///   milliseconds since epoch.
/// * `web_search` : Boolean flag indicating whether the task has web search
///   capabilities enabled.
///
/// Returns a new `Task` instance with the specified configuration and default
/// values for status (set to idle) and an empty message queue.
fn Task::new(
  name? : String,
  id~ : @uuid.Uuid,
  cwd~ : String,
  port~ : Int,
  created~ : @clock.Timestamp,
  web_search~ : Bool,
) -> Task {
  Task::{
    name,
    id,
    cwd,
    port,
    status: @server.Idle,
    queued_messages: [],
    created,
    web_search,
  }
}

///|
/// Message queued by agent
priv struct QueuedMessage {
  /// Unique identifier for the queued message.
  id : String
  /// JSON payload containing the message data to be delivered.
  message : Json
} derive(ToJson, @json.FromJson)
