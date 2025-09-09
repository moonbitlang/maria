///|
struct AutoTools {
  working_directory : String?
  configure_flags : Array[String]
}

///|
impl @json.FromJson for AutoTools with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> AutoTools raise @json.JsonDecodeError {
  let working_directory : String? = if json
    is { "working-directory": String(working_directory), .. } {
    Some(working_directory)
  } else {
    None
  }
  let configure_flags : Array[String] = if json
    is { "configure-flags": flags, .. } {
    @json.from_json(flags, path=json_path.add_key("configure-flags"))
  } else {
    []
  }
  AutoTools::{ working_directory, configure_flags }
}

///|
priv enum Source {
  Archive(url~ : String)
}

///|
impl @json.FromJson for Source with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Source raise @json.JsonDecodeError {
  guard json is { "type": String(type_), .. } else {
    raise @json.JsonDecodeError(
      (json_path.add_key("type"), "Missing required field 'type'"),
    )
  }
  match type_ {
    "archive" => {
      guard json is { "url": String(url), .. } else {
        raise @json.JsonDecodeError(
          (
            json_path.add_key("url"),
            "Missing required field 'url' for source type 'archive'",
          ),
        )
      }
      return Source::Archive(url~)
    }
    _ =>
      raise @json.JsonDecodeError(
        (json_path.add_key("type"), "Unknown source type '\{type_}'"),
      )
  }
}

///|
priv enum BuildStep {
  AutoTools(AutoTools)
}

///|
impl @json.FromJson for BuildStep with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> BuildStep raise @json.JsonDecodeError {
  guard json is { "type": String(type_), .. } else {
    raise @json.JsonDecodeError(
      (json_path.add_key("type"), "Missing required field 'type'"),
    )
  }
  match type_ {
    "autotools" => {
      let autotools : AutoTools = @json.from_json(json, path=json_path)
      return BuildStep::AutoTools(autotools)
    }
    _ =>
      raise @json.JsonDecodeError(
        (json_path.add_key("type"), "Unknown build type '\{type_}'"),
      )
  }
}

///|
priv struct Build {
  steps : Array[BuildStep]
}

///|
impl @json.FromJson for Build with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Build raise @json.JsonDecodeError {
  guard json is { "steps": steps, .. } else {
    raise @json.JsonDecodeError(
      (json_path.add_key("steps"), "Missing required field 'steps'"),
    )
  }
  let steps : Array[BuildStep] = @json.from_json(
    steps,
    path=json_path.add_key("steps"),
  )
  Build::{ steps, }
}

///|
struct Config {
  package_ : String
  libraries : Array[String]
}

///|
impl @json.FromJson for Config with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Config raise @json.JsonDecodeError {
  guard json is { "package": String(package_), .. } else {
    raise @json.JsonDecodeError(
      (json_path.add_key("package"), "Missing required field 'package'"),
    )
  }
  let libraries : Array[String] = if json is { "libraries": libs, .. } {
    @json.from_json(libs, path=json_path.add_key("libraries"))
  } else {
    []
  }
  Config::{ package_, libraries }
}

///|
priv struct Manifest {
  source : Array[Source]
  build : Build
  artifacts : Array[Artifact]
  configs : Array[Config]
}

///|
impl @json.FromJson for Manifest with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Manifest raise @json.JsonDecodeError {
  guard json is { "source": source, .. } else {
    raise @json.JsonDecodeError(
      (json_path.add_key("source"), "Missing required field 'source'"),
    )
  }
  let source : Array[Source] = @json.from_json(
    source,
    path=json_path.add_key("source"),
  )
  guard json is { "build": build, .. } else {
    raise @json.JsonDecodeError(
      (json_path.add_key("build"), "Missing required field 'build'"),
    )
  }
  let build : Build = @json.from_json(build, path=json_path.add_key("build"))
  guard json is { "configs": config, .. } else {
    raise @json.JsonDecodeError(
      (json_path.add_key("configs"), "Missing required field 'config'"),
    )
  }
  let artifacts : Array[Artifact] = if json is { "artifacts": arts, .. } {
    @json.from_json(arts, path=json_path.add_key("artifacts"))
  } else {
    []
  }
  let configs : Array[Config] = @json.from_json(
    config,
    path=json_path.add_key("configs"),
  )
  Manifest::{ source, build, configs, artifacts }
}

///|
async fn read_file(path : Bytes) -> String raise {
  let file = @fs.open(path, mode=ReadOnly)
  @utf8.decode(file.read_all())
}

///|
async fn remove_directory(path : Bytes) -> Unit raise {
  let dir = @fs.opendir(path)
  defer dir.close()
  for entry in dir.read_all() {
    let entry = @path.join(path, entry)
    match @fs.kind(entry) {
      Directory => remove_directory(entry)
      _ => @fs.remove(entry)
    }
  }
  @fs.rmdir(path)
}

///|
async fn spawn(
  command : Bytes,
  args : Array[Bytes],
  cwd~ : Bytes,
) -> Unit raise {
  @async.with_task_group(group => {
    let output = @pipe.pipe()
    group.spawn_bg(() => {
      let buf : FixedArray[Byte] = FixedArray::make(1024, 0)
      loop output.0.read(buf) {
        0 => break
        n => {
          @pipe.stderr.write(buf.unsafe_reinterpret_as_bytes()[0:n])
          continue output.0.read(buf)
        }
      }
    })
    let status = @process.run(
      command,
      args,
      stdout=output.1,
      stderr=output.1,
      cwd~,
    ) catch {
      error =>
        fail(
          "Failed to run \{@utf8.decode(command)} @ \{@utf8.decode(cwd)}: \{error}",
        )
    }
    guard status is 0 else {
      fail(
        "Failed to run \{@utf8.decode(command)} @ \{@utf8.decode(cwd)}: exit code \{status}",
      )
    }
  })
}

///|
struct Artifact {
  path : String
}

///|
impl @json.FromJson for Artifact with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Artifact raise @json.JsonDecodeError {
  guard json is { "path": String(path), .. } else {
    raise @json.JsonDecodeError(
      (json_path.add_key("path"), "Missing required field 'path'"),
    )
  }
  Artifact::{ path, }
}

///|
let uv : Result[@uv.Loop, @uv.Errno] = try? @uv.Loop::new()

///|
fn main {
  @async.with_event_loop(_ => {
    let args = @uv.args()[1:]
    let mut project = @uv.cwd()
    let mut manifest = None
    let mut allow_build = false
    loop args {
      [] => break
      ["--project"] => fail("Missing argument for --project")
      ["--project", project_argument, .. args] => {
        project = project_argument
        continue args
      }
      ["--manifest"] => fail("Missing argument for --manifest")
      ["--manifest", manifest_argument, .. args] => {
        manifest = Some(manifest_argument)
        continue args
      }
      ["--build", .. args] => {
        allow_build = true
        continue args
      }
      [arg, ..] => fail("Unknown argument: \{arg}")
    }
    let manifest = match manifest {
      Some(manifest) => manifest
      None => @path.join(project, "manifest.json")
    }
    let prefix = @path.join(project, ".local")
    if !@fs.exists(prefix) {
      @fs.mkdir(prefix, permission=0o755)
    }
    let prefix_src = @path.join(prefix, "src")
    if !@fs.exists(prefix_src) {
      @fs.mkdir(prefix_src, permission=0o755)
    }
    let prefix_var = @path.join(prefix, "var")
    if !@fs.exists(prefix_var) {
      @fs.mkdir(prefix_var, permission=0o755)
    }
    let mut source_mtime = uv
      .unwrap_or_error()
      .fs_stat_sync(manifest)
      .mtim_sec()
    let manifest = read_file(manifest)
    let manifest = @json.parse(manifest)
    let manifest : Manifest = @json.from_json(manifest)
    for source in manifest.source {
      match source {
        Archive(url~) => {
          let url = @utf8.encode(url)
          let basename = @path.basename(url).to_bytes()
          let path = @path.join(prefix_src, basename)
          if @fs.exists(path) {
            let stat = uv.unwrap_or_error().fs_stat_sync(path)
            let mtime = stat.mtim_sec()
            if mtime > source_mtime {
              source_mtime = mtime
            }
          }
        }
      }
    }
    let mut rebuild = false
    for artifact in manifest.artifacts {
      let artifact_path = @path.join(prefix, @utf8.encode(artifact.path))
      let mtime = uv.unwrap_or_error().fs_stat_sync(artifact_path).mtim_sec() catch {
        _ => {
          rebuild = true
          break
        }
      }
      if mtime < source_mtime {
        rebuild = true
        break
      }
    }
    if rebuild {
      if !allow_build {
        @pipe.stderr.write("Error: artifacts are missing or outdated, please run with --build to build them\n")
        println("{}")
        return
      }
      @pipe.stderr.write("Artifacts are outdated, rebuilding...\n")
      for source in manifest.source {
        match source {
          Archive(url~) => {
            let url = @utf8.encode(url)
            let basename = @path.basename(url).to_bytes()
            if !@fs.exists(@path.join(prefix_src, basename)) {
              spawn("wget", [url], cwd=prefix_src)
            }
            match basename {
              [.. stem, .. ".tar.gz"] => {
                if @fs.exists(@path.join(prefix_src, stem)) {
                  remove_directory(@path.join(prefix_src, stem))
                }
                spawn("tar", ["-xzf", basename], cwd=prefix_src)
              }
              [..] => fail("Unsupported archive format: \{url}")
            }
          }
        }
      }
      for step in manifest.build.steps {
        match step {
          AutoTools(autotools) => {
            let working_directory = if autotools.working_directory is Some(dir) {
              @path.join(prefix_src, @utf8.encode(dir))
            } else {
              prefix_src
            }
            let configure_flags : Array[Bytes] = ["--prefix=" + prefix]
            for flag in autotools.configure_flags {
              configure_flags.push(@utf8.encode(flag))
            }
            spawn("./configure", configure_flags, cwd=working_directory)
            spawn("make", [], cwd=working_directory)
            spawn("make", ["install"], cwd=working_directory)
          }
        }
      }
    } else {
      @pipe.stderr.write("Artifacts are up to date, skipping build.\n")
    }
    let prefix_include = @path.join(prefix, "include")
    if !@fs.exists(prefix_include) {
      fail(
        "Include directory \{prefix_include} does not exist after installation",
      )
    }
    let prefix_lib = @path.join(prefix, "lib")
    if !@fs.exists(prefix_lib) {
      fail("Lib directory \{prefix_lib} does not exist after installation")
    }
    let cc = match @uv.os_getenv("CC") {
      Some(cc) => @utf8.decode(cc)
      None => if @uv.os_uname().sysname() == "Windows_NT" { "cl" } else { "cc" }
    }
    let cc_flags : Array[String] = []
    if cc is ("cl" | "cl.exe") {
      cc_flags.push("/I\{prefix_include}")
    } else {
      cc_flags.push("-I\{@utf8.decode(prefix_include)}")
    }
    let link_configs : Array[Json] = []
    for config in manifest.configs {
      let link_libs = []
      let link_search_paths = [@utf8.decode(prefix_lib)]
      for lib in config.libraries {
        if cc is ("cl" | "cl.exe") {
          link_libs.push("\{lib}.lib")
        } else {
          link_libs.push(lib)
        }
      }
      link_configs.push({
        "package": config.package_,
        "link_libs": link_libs,
        "link_search_paths": link_search_paths,
      })
    }
    let config_json : Json = {
      "vars": { "CC": cc, "CC_FLAGS": cc_flags.join(" ") },
      "link_configs": link_configs,
    }
    println(config_json.stringify(indent=2))
  }) catch {
    error => println("Error: \{error}")
  }
}
