# Developer Notes

## Code Agent Safety Trade-off

`maria` is in the early stages of development, so it doesn't provide any safety
mechanisms yet. We recommend users use the following strategies to protect end
users.

1. Run `maria` in a sandbox, e.g., a Docker container, VM, or restricted
   environment.
2. Use a version control system to protect the user codebase or other important
   files.
3. `maria` itself provides simple path privilege check. (currently **not
   supported** yet)

## Internal Packages Design Principles

Some OS APIs are hard to provide robust enough error handling at the call site,
so only handling common error cases is reasonable for fast development and
providing useful features. If some error case is rare, we would mark it with a
`won't fix` label for this issue instead of `Close as not planned`.

Another case is path operations. Windows paths and Unix paths have many edge
cases, and it's hard to define well-defined behavior, so when we add APIs in
`internal/path`, you should follow the following API design conventions:

- `test "foo"` for common cases

- `test "foo/ edge cases"` for edge cases correctly handled

- `test "foo/ undefined behavior"` some cases aren't handled, but users should
  not abuse this behavior

- `test "foo/ failed cases"` for providing a default behavior when an error occurs.

By the way, if other internal packages cannot have simple and elegant API
design, you can refer to the above conventions.
