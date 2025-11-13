///|
priv struct Spawn {
  command : String
  arguments : Array[String]
  cwd : String?
  process : @aqueue.Queue[Result[Process, Error]]
}

///|
pub struct Manager {
  mut id : Int
  process : Map[Pid, Process]
  priv spawn : @aqueue.Queue[Spawn]
}

///|
pub fn Manager::new() -> Manager {
  Manager::{ id: 0, process: {}, spawn: @aqueue.Queue::new() }
}

///|
fn Manager::new_pid(self : Manager) -> Pid {
  let id = self.id
  self.id += 1
  id
}

///|
struct Pid(Int) derive(Hash, Eq)

///|
pub impl ToJson for Pid with to_json(self : Pid) -> Json {
  self.0.to_json()
}

///|
pub impl Show for Pid with output(self : Pid, logger : &Logger) -> Unit {
  logger.write_string(self.0.to_string())
}

///|
pub struct Process {
  pid : Pid
  priv status : Ref[Int?]
  priv task : @async.Task[Int]
  stdout : @pipe.PipeRead
  stderr : @pipe.PipeRead
}

///|
pub fn Process::status(self : Process) -> Int? {
  self.status.val
}

///|
pub async fn Manager::spawn(
  self : Manager,
  command : String,
  arguments : Array[String],
  cwd? : String,
) -> Process {
  let process = @aqueue.Queue::new()
  self.spawn.put(Spawn::{
    command,
    arguments,
    cwd: cwd.map(_.to_string()),
    process,
  })
  process.get().unwrap_or_error()
}

///|
pub async fn Manager::wait(self : Manager, pid : Pid) -> Int {
  self.process[pid].task.wait()
}

///|
pub async fn Process::wait(self : Process) -> Int {
  self.task.wait()
}

///|
pub async fn Manager::start(self : Manager) -> Unit {
  @async.with_task_group(group => while true {
    let spawn = self.spawn.get()
    try {
      let pid = self.new_pid()
      let refer_status = Ref::new(None)
      let stderr = @process.read_from_process()
      let stdout = @process.read_from_process()
      let task = group.spawn(() => {
        let status = @process.run(
          spawn.command,
          spawn.arguments,
          stdout=stdout.1,
          stderr=stderr.1,
          cwd?=spawn.cwd,
        )
        refer_status.val = Some(status)
        status
      })
      let process = Process::{
        pid,
        status: refer_status,
        task,
        stdout: stdout.0,
        stderr: stderr.0,
      }
      self.process[pid] = process
      process
    } catch {
      error => spawn.process.put(Err(error))
    } noraise {
      process => spawn.process.put(Ok(process))
    }
  }) catch {
    error => {
      self.process.clear()
      while self.spawn.try_get() is Some(spawn) {
        spawn.process.put(Err(error))
      }
      raise error
    }
  }
}

///|
pub fn Manager::list(self : Manager) -> Array[Process] {
  self.process.values().to_array()
}

///|
pub fn Manager::get(self : Manager, pid : Pid) -> Process? {
  self.process.get(pid)
}
