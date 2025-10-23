# Mock Utilities

This package contains the mock harness used by Maria's test suite. It exposes
helpers that spin up a temporary project workspace with deterministic
infrastructure so asynchronous tests can interact with the filesystem and other
side effects without touching the developer's machine.

## What `@mock.run` Provides

- Creates an isolated temporary package layout that mirrors the module under
  test and tears it down after the test finishes.
- Captures logs under `__trajectories__/<test-name>` using the Pino transport so
  long-running tasks can be inspected post-mortem.
- Injects mock implementations for time, randomness, and UUID generation to
  keep snapshot tests deterministic.
- Filters sensitive fields (paths, environment variables, secrets) from JSON and
  string outputs produced inside the mock context to avoid leaking host data.

Call `@mock.run(t, ctx => { ... })` inside an `async test` to receive a
`Context` instance. The wrapper supports a configurable timeout and automatic
retry logic; see `taco.mbt` for the full contract.

```moonbit async
async test "writes file" (t : @test.T) {
  @mock.run(t, async ctx => {
    let file = ctx.add_file("output.txt", content="hello")
    let text = file.read()
    @json.inspect(text, content="hello")
  })
}
```

## Using the `Context`

A `Context` instance is passed into your closure as `ctx`. The most common
operations are:

- `ctx.add_file(name, content=...)` / `ctx.add_files(...)` /
  `ctx.add_directory(...)` to pre-seed the workspace tree.
- `ctx.json(value)` and `ctx.show(value)` when emitting data that ends up in
  inspect snapshots or logs, so secrets get masked automatically.
- `ctx.logger` for structured logging (already configured to write to
  `__trajectories__/<test-name>`).
- `ctx.group` to spawn background work or schedule `add_defer` cleanups that run
  before the mock environment is torn down.

Other handy fields include `ctx.cwd` (root directory wrapper), `ctx.clock` (a
monotonic mock clock you can advance manually), `ctx.rand` (deterministic RNG),
and `ctx.uuid` (deterministic UUID generator built on that RNG).

```moonbit async
async test "context helpers" (t : @test.T) {
  @mock.run(t, async ctx => {
    let config_dir = ctx.add_directory("config")
    ctx.add_file("config/app.json", content="{\"port\": 8080}")

    ctx.logger.info("config", ctx.json({ cwd: ctx.cwd.path() }))

    ctx.group.add_defer(() => {
      @json.inspect(config_dir.list().length(), content=1)
    })
  })
}
```

## Lower-Level Helpers

- `Directory` and `File` provide focused filesystem helpers (create, list, read,
  write) that the context delegates to.
- `with_home(dir, f)` temporarily redirects `HOME` to a mock directory, which is
  useful when testing code that reads configuration from user dotfiles.
- `skip(message)` raises an internal `Skip` error that is caught by `run`,
  allowing a test to exit early without failing.

See `mock_test.mbt` for usage examples that exercise retry logic.
