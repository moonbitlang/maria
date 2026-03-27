///|
/// Whitebox tests for private helper functions: generate_plist, generate_unit,
/// and read_daemon_info.

///|
test "generate_plist - snapshot" {
  let config = ServiceConfig::{
    exec_path: "/usr/local/bin/maria",
    port: 7890,
    serve: "/workspace",
    home: "/Users/testuser",
  }
  inspect(
    generate_plist(config),
    content=(
      #|<?xml version="1.0" encoding="UTF-8"?>
      #|<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      #|<plist version="1.0">
      #|<dict>
      #|  <key>Label</key>
      #|  <string>com.moonbitlang.maria</string>
      #|  <key>ProgramArguments</key>
      #|  <array>
      #|    <string>/usr/local/bin/maria</string>
      #|    <string>daemon</string>
      #|    <string>--port</string>
      #|    <string>7890</string>
      #|    <string>--serve</string>
      #|    <string>/workspace</string>
      #|    <string>--managed</string>
      #|  </array>
      #|  <key>KeepAlive</key>
      #|  <true/>
      #|  <key>RunAtLoad</key>
      #|  <true/>
      #|  <key>StandardOutPath</key>
      #|  <string>/Users/testuser/.moonagent/daemon.stdout.log</string>
      #|  <key>StandardErrorPath</key>
      #|  <string>/Users/testuser/.moonagent/daemon.stderr.log</string>
      #|</dict>
      #|</plist>
      #|
    ),
  )
}

///|
test "generate_unit - snapshot" {
  let config = ServiceConfig::{
    exec_path: "/usr/local/bin/maria",
    port: 7890,
    serve: "/workspace",
    home: "/home/testuser",
  }
  inspect(
    generate_unit(config),
    content=(
      #|[Unit]
      #|Description=Maria AI Coding Agent Daemon
      #|
      #|[Service]
      #|ExecStart=/usr/local/bin/maria daemon --port 7890 --serve /workspace --managed
      #|Restart=on-failure
      #|RestartSec=2
      #|Environment=HOME=/home/testuser
      #|
      #|[Install]
      #|WantedBy=default.target
      #|
    ),
  )
}

///|
async test "read_daemon_info - not installed" (t : @test.Test) {
  @mock.run(t, mock => {
    let status = read_daemon_info(mock.cwd.path())
    inspect(status, content="NotInstalled")
  })
}

///|
async test "read_daemon_info - stopped (invalid JSON)" (t : @test.Test) {
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
    let status = read_daemon_info(home)
    inspect(status, content="Stopped")
  })
}

///|
async test "read_daemon_info - stopped (missing required fields)" (
  t : @test.Test,
) {
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
    let status = read_daemon_info(home)
    inspect(status, content="Stopped")
  })
}

///|
async test "read_daemon_info - stopped (dead PID)" (t : @test.Test) {
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
    let status = read_daemon_info(home)
    inspect(status, content="Stopped")
  })
}

///|
async test "read_daemon_info - running (current process PID)" (t : @test.Test) {
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
    let status = read_daemon_info(home)
    guard status is Running(port~, version~, ..) else {
      fail("Expected Running, got \{status}")
    }
    inspect(port, content="12345")
    inspect(version, content="1.2.3")
  })
}
