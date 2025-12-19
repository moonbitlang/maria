# test-to-be-killed

This package contains a simple executable that holds a lock file for
indefinitely. This is useful for testing the daemon's ability to detect and
terminate older versions of itself, specially those that do not respond to HTTP
shutdown requests.

## Usage

In one terminal, start the test-to-be-killed executable:

```bash
moon run cmd/test-to-be-killed
```

And in another terminal, start daemon normally:

```bash
moon run cmd/main -- daemon
```

If the logic is correct, the newly started daemon should terminate
`cmd/test-to-be-killed` in 10 seconds.
