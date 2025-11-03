///|
pub struct Job {
  id : Id
  name : String
  description : String?
  command : String
  cwd : String
  stdout : String
  stderr : String
  priv process : @spawn.Process
}

///|
pub fn Job::status(self : Job) -> Int? {
  self.process.status()
}

///|
pub async fn Job::wait(self : Job) -> Int {
  self.process.wait()
}

///|
pub impl ToJson for Job with to_json(self : Job) -> Json {
  let json : Map[String, Json] = {
    "id": self.id.0.to_json(),
    "name": self.name.to_json(),
    "command": self.command.to_json(),
    "cwd": self.cwd.to_json(),
    "stdout": self.stdout.to_json(),
    "stderr": self.stderr.to_json(),
  }
  if self.description is Some(desc) {
    json["description"] = desc.to_json()
  }
  Json::object(json)
}

///|
pub struct Manager {
  cwd : String
  priv mut id : Int
  priv process : @spawn.Manager
  priv jobs : Map[Id, Job]
}

///|
struct Id(Int) derive(Hash, Eq)

///|
pub impl Show for Id with output(self : Id, logger : &Logger) -> Unit {
  Show::output(self.0, logger)
}

///|
pub impl ToJson for Id with to_json(self : Id) -> Json {
  self.0.to_json()
}

///|
pub impl @json.FromJson for Id with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Id {
  let value : Int = @json.FromJson::from_json(json, json_path)
  Id(value)
}

///|
pub fn Manager::new(cwd~ : String) -> Manager {
  Manager::{ cwd, id: 0, process: @spawn.Manager::new(cwd~), jobs: {} }
}

///|
fn Manager::new_id(self : Manager) -> Id {
  let id = self.id
  self.id += 1
  Id(id)
}

///|
pub async fn Manager::spawn(
  self : Manager,
  name~ : String,
  description? : String,
  command~ : String,
  cwd? : String,
) -> Job {
  let cwd = match cwd {
    Some(cwd) => cwd
    None => self.cwd
  }
  let id = self.new_id()
  let jobs_dir = self.cwd
    |> @path.join(".moonagent")
    |> @path.join("jobs")
    |> @path.join("\{id.0}")
  @fs.make_directory(jobs_dir, recursive=true) catch { error => @errortrace.reraise(error) }
  let stdout_path = jobs_dir |> @path.join("stdout")
  @fs.FileRead::create(stdout_path).close() catch { error => @errortrace.reraise(error) }
  let stderr_path = jobs_dir |> @path.join("stderr")
  @fs.FileRead::create(stderr_path).close() catch { error => @errortrace.reraise(error) }
  let process = self.process.spawn(
    "sh",
    ["-c", command],
    stderr=File(stderr_path),
    stdout=File(stdout_path),
    cwd~,
  )
  let job = Job::{
    id,
    name,
    description,
    command,
    cwd,
    stdout: stdout_path,
    stderr: stderr_path,
    process,
  }
  self.jobs[id] = job
  job
}

///|
pub suberror InvalidJobId Id

///|
pub async fn Manager::wait(self : Manager, id : Id) -> Int {
  guard self.jobs.get(id) is Some(job) else { raise InvalidJobId(id) }
  job.wait()
}

///|
pub async fn Manager::start(self : Manager) -> Unit {
  self.process.start()
}

///|
pub async fn Manager::list(self : Manager) -> Array[Job] {
  self.jobs.values().to_array()
}

///|
pub fn Manager::get(self : Manager, id : Id) -> Job? {
  self.jobs.get(id)
}
