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

## Error Handling

LLM is not deterministic, so it is hard to replicate some errors. Therefore, we
prefer debuggability over performance when it comes to error handling.

Typically there are three types of errors:

1. Invalid usage: the errors that are caused by invalid usage of the API, e.g.,
   passing invalid arguments to a function, breaks the preconditions, etc. These
   errors should be diagnosed and reported to the API user by raising an error,
   or by provided a sane default behavior.

   Never use `panic` or `abort` for these errors.

2. External errors: errors that are caused by external factors, e.g., network
   errors, file system errors, etc. These errors should be logged and reported
   to the user as much as possible.

   Never use `panic` or `abort` for these errors.

3. Programmer errors: errors that are caused by bugs in the code, e.g., index
   out of bounds, breaks the preconditions, etc. These errors should use `abort`
   to terminate the program with a detailed error message describing the the
   error.

   Use `abort` for these errors, and never use `panic` or `guard` statements
   without `else` branch, as they will terminate the program _without_ any error
   message.

Also, as `moonbitlang/async` uses error-handling to provide cancellation
mechanism, eating up errors when handling errors from async functions is
strongly discouraged. However one might still want to eat up errors in some
cases, for example, when implementing retrying logic. In such cases, please
always checks if the current coroutine is being cancelled by calling
`@async.is_being_cancelled()` before eating up errors. If the coroutine is being
cancelled, one must re-raise the error to propagate the cancellation.

Additionally, it is almost always a bad idea to wrap the generic error as a new
error, as it makes it hard to pattern-matching on the error type. For example,

```moonbit
suberror WrapA(Error)
```

To match all possible variant of `@os_error.OsError(...)`, one would need to
write:

```moonbit test
try {
  ...
} catch {
  @os_error.OsError(...) => { ... }
  WrapA(@os_error.OsError(...)) => { ... }
  WrapA(WrapA(@os_error.OsError(...))) => { ... }
  ...
}
```
