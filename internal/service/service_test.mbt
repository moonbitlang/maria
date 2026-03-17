///|
test "Backend::to_json - all variants" {
  json_inspect(Backend::Launchd, content="launchd")
  json_inspect(Backend::Systemd, content="systemd")
  json_inspect(Backend::Detach, content="detach")
}

///|
test "Backend::from_json - known values" {
  let launchd : Backend = @json.from_json(@json.parse("\"launchd\""))
  inspect(launchd, content="Launchd")
  let systemd : Backend = @json.from_json(@json.parse("\"systemd\""))
  inspect(systemd, content="Systemd")
  let detach : Backend = @json.from_json(@json.parse("\"detach\""))
  inspect(detach, content="Detach")
}

///|
test "Backend::from_json - unknown values fall back to Detach" {
  let unknown : Backend = @json.from_json(@json.parse("\"unknown_value\""))
  inspect(unknown, content="Detach")
  let null_val : Backend = @json.from_json(@json.parse("null"))
  inspect(null_val, content="Detach")
  let num_val : Backend = @json.from_json(@json.parse("42"))
  inspect(num_val, content="Detach")
}

///|
test "Backend JSON round-trip" {
  let variants : Array[Backend] = [Launchd, Systemd, Detach]
  for b in variants {
    let b2 : Backend = @json.from_json(b.to_json())
    inspect(b == b2, content="true")
  }
}

///|
test "ServiceManager::backend" {
  let config = ServiceConfig::{
    exec_path: "/usr/local/bin/maria",
    port: 8080,
    serve: "/workspace",
    home: "/home/user",
  }
  inspect(ServiceManager::Launchd(config).backend(), content="Launchd")
  inspect(ServiceManager::Systemd(config).backend(), content="Systemd")
  inspect(ServiceManager::Detach(config).backend(), content="Detach")
}

///|
test "ServiceManager::config" {
  let config = ServiceConfig::{
    exec_path: "/usr/local/bin/maria",
    port: 7890,
    serve: "/projects",
    home: "/home/testuser",
  }
  for
    mgr in [
      ServiceManager::Launchd(config),
      ServiceManager::Systemd(config),
      ServiceManager::Detach(config),
    ] {
    let c = mgr.config()
    inspect(c.exec_path, content="/usr/local/bin/maria")
    inspect(c.port, content="7890")
    inspect(c.serve, content="/projects")
    inspect(c.home, content="/home/testuser")
  }
}

///|
test "detect - returns variant matching current platform" {
  let config = ServiceConfig::{
    exec_path: "/usr/local/bin/maria",
    port: 8080,
    serve: "/workspace",
    home: "/home/user",
  }
  let mgr = detect(config)
  match @os.platform() {
    MacOS => inspect(mgr.backend(), content="Launchd")
    Linux => inspect(mgr.backend(), content="Systemd")
    Unknown => inspect(mgr.backend(), content="Detach")
  }
}

///|
async test "ServiceManager::status - not installed" (t : @test.Test) {
  @mock.run(t, mock => {
    let config = ServiceConfig::{
      exec_path: "/usr/local/bin/maria",
      port: 8080,
      serve: "/workspace",
      home: mock.cwd.path(),
    }
    let status = ServiceManager::Detach(config).status()
    inspect(status, content="NotInstalled")
  })
}

///|
async test "ServiceManager::status - stopped (invalid JSON)" (t : @test.Test) {
  @mock.run(t, mock => {
    let home = mock.cwd.path()
    @fsx.make_directory(
      home |> @pathx.join(".moonagent"),
      recursive=true,
      exists_ok=true,
    )
    @fsx.write_to_file(
      home |> @pathx.join(".moonagent") |> @pathx.join("daemon.json"),
      "not valid json",
    )
    let config = ServiceConfig::{
      exec_path: "/usr/local/bin/maria",
      port: 8080,
      serve: "/workspace",
      home,
    }
    let status = ServiceManager::Detach(config).status()
    inspect(status, content="Stopped")
  })
}

///|
async test "ServiceManager::status - stopped (missing fields)" (t : @test.Test) {
  @mock.run(t, mock => {
    let home = mock.cwd.path()
    @fsx.make_directory(
      home |> @pathx.join(".moonagent"),
      recursive=true,
      exists_ok=true,
    )
    @fsx.write_to_file(
      home |> @pathx.join(".moonagent") |> @pathx.join("daemon.json"),
      "{\"version\": \"1.0.0\"}",
    )
    let config = ServiceConfig::{
      exec_path: "/usr/local/bin/maria",
      port: 8080,
      serve: "/workspace",
      home,
    }
    let status = ServiceManager::Detach(config).status()
    inspect(status, content="Stopped")
  })
}

///|
async test "ServiceManager::status - stopped (dead PID)" (t : @test.Test) {
  @mock.run(t, mock => {
    let home = mock.cwd.path()
    @fsx.make_directory(
      home |> @pathx.join(".moonagent"),
      recursive=true,
      exists_ok=true,
    )
    // PID 2147483647 (INT_MAX) is virtually guaranteed not to exist
    @fsx.write_to_file(
      home |> @pathx.join(".moonagent") |> @pathx.join("daemon.json"),
      "{\"pid\": 2147483647, \"port\": 9999, \"version\": \"1.0.0\"}",
    )
    let config = ServiceConfig::{
      exec_path: "/usr/local/bin/maria",
      port: 8080,
      serve: "/workspace",
      home,
    }
    let status = ServiceManager::Detach(config).status()
    inspect(status, content="Stopped")
  })
}

///|
async test "ServiceManager::status - running (current process PID)" (
  t : @test.Test,
) {
  @mock.run(t, mock => {
    let home = mock.cwd.path()
    let pid = @spawn.getpid()
    @fsx.make_directory(
      home |> @pathx.join(".moonagent"),
      recursive=true,
      exists_ok=true,
    )
    @fsx.write_to_file(
      home |> @pathx.join(".moonagent") |> @pathx.join("daemon.json"),
      "{\"pid\": \{pid}, \"port\": 12345, \"version\": \"1.2.3\"}",
    )
    let config = ServiceConfig::{
      exec_path: "/usr/local/bin/maria",
      port: 8080,
      serve: "/workspace",
      home,
    }
    let status = ServiceManager::Detach(config).status()
    guard status is Running(port~, version~, ..) else {
      fail("Expected Running, got \{status}")
    }
    inspect(port, content="12345")
    inspect(version, content="1.2.3")
  })
}
