# Develop Note

## Code Agent Safety Trade off

`maria` is in the early stages of development, so doesn't provide any safety mechanisms yet.
So we recommend user use below strategies to protect end user.

1. run `maria` in sandbox. e.g. docker container, VM, or restricted environment.
2. version control system protect user codebase or other important files.
3. `maria` it self provide simple path privilege check. (current **not supported** yet)

## internal packages design primsiples

some OS API is hard to provide robust enough error handling in call site, so only handle common error cases is reasonable for fast development and provide useful features.
if some error case is rare, we would mark as `won't fix` label for this issue instead of `Close as not planned`.

another cases is path operation, Windows path and Unix path have many edge cases, and hard to define well behavior,
so when we add API in `internal/path`, you should follow below API design conventions:

- `test "foo"` for common cases

- `test "foo/ edge cases"` for edge cases correctly handled

- `test "foo/ undefined behavior"` some cases doesn't handle, but user should not abuse this behavior

- `test "foo/ failed cases"` for providing a default behavior when error occurs.

by the way, if other internal packages can not have simple and elegant API design, you can refer to above conventions.
