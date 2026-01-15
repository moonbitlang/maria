///|
priv struct Spawn {
  command : String
  arguments : Array[String]
  stderr : RedirectOutput
  stdout : RedirectOutput
  cwd : String?
  process : @aqueue.Queue[Result[Process, Error]]
  env : Map[String, String]?
}

///|
struct Manager {
  cwd : String
  process : Map[Pid, Process]
  spawn : @aqueue.Queue[Spawn?]
}

///|
pub fn Manager::new(cwd~ : String) -> Manager {
  Manager::{ cwd, process: {}, spawn: @aqueue.Queue::new(kind=Unbounded) }
}

///|
struct Pid(Int) derive(Hash, Eq)

///|
pub fn Pid::to_int(self : Pid) -> Int {
  self.0
}

///|
pub impl ToJson for Pid with to_json(self : Pid) -> Json {
  self.0.to_json()
}

///|
pub impl Show for Pid with output(self : Pid, logger : &Logger) -> Unit {
  logger.write_string(self.0.to_string())
}

///|
priv enum ProcessStatus {
  Running(@async.Task[Int])
  Exited(Int)
}

///|
pub struct Process {
  pid : Pid
  priv mut status : ProcessStatus
  stdout : RedirectOutput
  stderr : RedirectOutput
}

///|
pub fn Process::status(self : Process) -> Int? {
  match self.status {
    Running(_) => None
    Exited(code) => Some(code)
  }
}

///|
struct Buffer {
  mut chunks : Array[String]
}

///|
pub fn Buffer::new() -> Buffer {
  Buffer::{ chunks: [] }
}

///|
fn Buffer::write(self : Buffer, chunk : String) -> Unit {
  self.chunks.push(chunk)
}

///|
pub fn Buffer::to_string(self : Buffer) -> String {
  let string = self.chunks.join("")
  self.chunks = [string]
  string
}

///|
pub(all) enum RedirectOutput {
  Inherit
  Capture(Buffer)
  File(String)
  Sink
}

///|
pub async fn Manager::spawn(
  self : Manager,
  command : String,
  arguments : Array[String],
  stderr? : RedirectOutput = Inherit,
  stdout? : RedirectOutput = Inherit,
  cwd? : String,
  env? : Map[String, String],
) -> Process {
  let process = @aqueue.Queue::new(kind=Unbounded)
  self.spawn.put(
    Some(Spawn::{
      command,
      arguments,
      stderr,
      stdout,
      cwd: cwd.map(_.to_string()),
      process,
      env,
    }),
  )
  process.get().unwrap_or_error()
}

///|
pub async fn Manager::wait(self : Manager, pid : Pid) -> Int {
  self.process[pid].wait()
}

///|
pub async fn Process::wait(self : Process) -> Int {
  match self.status {
    Exited(code) => return code
    Running(task) => {
      let status = task.wait()
      self.status = Exited(status)
      status
    }
  }
}

///|
pub async fn Manager::start(self : Manager) -> Unit {
  @async.with_task_group(group => {
    group.add_defer(() => {
      for _, p in self.process {
        guard p.status is Running(task) else { continue }
        kill(p.pid.0, @signal.sigkill) catch {
          error => {
            println("[WARN] Failed to kill process \{p.pid.0}: \{error}")
            continue
          }
        }
        ignore(task.wait())
      }
      self.process.clear()
    })
    async fn redirect_output(
      redirect : RedirectOutput,
    ) -> &@process.ProcessOutput? {
      match redirect {
        Capture(buffer) => {
          let pipe = @process.read_from_process()
          group.spawn_bg(() => {
            let buf = FixedArray::make(1024, b'0')
            while pipe.0.read(buf) is n && n > 0 {
              buffer.write(
                @encoding/utf8.decode_lossy(
                  buf.unsafe_reinterpret_as_bytes()[0:n],
                ),
              )
            }
          })
          Some(pipe.1)
        }
        Sink => {
          let pipe = @process.read_from_process()
          group.spawn_bg(() => {
            let buf = FixedArray::make(1024, b'0')
            while pipe.0.read(buf) is n && n > 0 {
              // discard data
            }
          })
          Some(pipe.1)
        }
        File(path) => Some(@process.redirect_to_file(path))
        Inherit => None
      }
    }

    while self.spawn.get() is Some(spawn) {
      try {
        let stderr = redirect_output(spawn.stderr)
        let stdout = redirect_output(spawn.stdout)
        let pid = @process.spawn_orphan(
          spawn.command,
          spawn.arguments,
          stderr?,
          stdout?,
          cwd=spawn.cwd.unwrap_or(self.cwd),
          extra_env?=spawn.env,
        )
        let task = group.spawn(() => @process.wait_pid(pid))
        let process = Process::{
          pid,
          status: Running(task),
          stdout: spawn.stdout,
          stderr: spawn.stderr,
        }
        self.process[pid] = process
        process
      } catch {
        error => spawn.process.put(Err(error))
      } noraise {
        process => spawn.process.put(Ok(process))
      }
    }
  }) catch {
    error => {
      println("[ERROR] Spawn manager encountered an error: \{error}")
      self.process.clear()
      while self.spawn.try_get() is Some(Some(spawn)) {
        spawn.process.try_put(Err(error)) |> ignore()
      }
      println(
        "[INFO] Spawn manager has been closed, re-raising error \{error}.",
      )
      raise error
    }
  }
}

///|
pub fn Manager::close(self : Manager) -> Unit {
  guard self.spawn.try_put(None)
}

///|
pub fn Manager::list(self : Manager) -> Array[Process] {
  self.process.values().to_array()
}

///|
pub fn Manager::get(self : Manager, pid : Pid) -> Process? {
  self.process.get(pid)
}
