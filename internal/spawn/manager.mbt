///|
priv struct Spawn {
  command : String
  arguments : Array[String]
  stderr : Redirect
  stdout : Redirect
  cwd : String?
  process : @aqueue.Queue[Result[Process, Error]]
}

///|
pub struct Manager {
  uuid : @uuid.Generator
  cwd : String
  process : Map[Pid, Process]
  priv spawn : @aqueue.Queue[Spawn]
}

///|
pub fn Manager::new(uuid~ : @uuid.Generator, cwd~ : String) -> Manager {
  Manager::{ uuid, cwd, process: {}, spawn: @aqueue.Queue::new() }
}

///|
struct Pid(@uuid.Uuid) derive(Show, Hash, Eq, ToJson, @json.FromJson)

///|
pub struct Process {
  pid : Pid
  priv status : @aqueue.Queue[Result[Int, Error]]
  stdout : @pipe.PipeRead?
  stderr : @pipe.PipeRead?
}

///|
pub(all) enum Redirect {
  Inherit
  Capture
}

///|
pub async fn Manager::spawn(
  self : Manager,
  command : StringView,
  arguments : Array[StringView],
  stderr? : Redirect = Inherit,
  stdout? : Redirect = Inherit,
  cwd? : StringView,
) -> Process {
  let process = @aqueue.Queue::new()
  self.spawn.put(Spawn::{
    command: command.to_string(),
    arguments: arguments.map(arg => arg.to_string()),
    stderr,
    stdout,
    cwd: cwd.map(_.to_string()),
    process,
  })
  process.get().unwrap_or_error()
}

///|
pub async fn Manager::wait(self : Manager, pid : Pid) -> Int {
  self.process[pid].status.get().unwrap_or_error()
}

///|
pub async fn Manager::start(self : Manager) -> Unit {
  @async.with_task_group(group => group.spawn_bg(() => while true {
    let spawn = self.spawn.get()
    group.spawn_bg(() => try {
      let pid = self.uuid.v4()
      let stderr = if spawn.stderr is Capture {
        Some(@process.read_from_process())
      } else {
        None
      }
      let stdout = if spawn.stdout is Capture {
        Some(@process.read_from_process())
      } else {
        None
      }
      let process = Process::{
        pid,
        status: @aqueue.Queue::new(),
        stdout: stdout.map(pipe => pipe.0),
        stderr: stderr.map(pipe => pipe.0),
      }
      self.process[pid] = process
      spawn.process.put(Ok(process))
      let status = try? @process.run(
          spawn.command,
          spawn.arguments,
          stderr?=stderr.map(pipe => pipe.1),
          stdout?=stdout.map(pipe => pipe.1),
          cwd?=spawn.cwd,
        )
      process.status.put(status)
    } catch {
      error => spawn.process.put(Err(error))
    })
  })) catch {
    error => {
      for _, process in self.process {
        process.status.put(Err(error))
      }
      raise error
    }
  }
}

///|
pub fn Manager::list(self : Manager) -> Array[Pid] {
  self.process.keys().to_array()
}

///|
pub fn Manager::get(self : Manager, pid : Pid) -> Process? {
  self.process.get(pid)
}
