///|
priv suberror Reraise (String, Error?)

///|
#callsite(autofill(loc))
pub fn[A] reraise(e : Error, loc~ : SourceLoc) -> A raise {
  match e {
    Reraise((msg, cause)) =>
      raise Reraise(
        (
          (
            $|\{msg}
            $|  at \{loc}
          ),
          cause,
        ),
      )
    Failure(msg) =>
      lexmatch msg {
        (prefix, "FAILED", rest) =>
          raise Reraise(
            (
              (
                $|Failed\{rest}
                $|  at \{prefix}
                $|  at \{loc}
              ),
              None,
            ),
          )
        _ => panic()
      }
    e => raise Reraise((e.to_string() + "\n  at \{loc}", None))
  }
}

///|
#callsite(autofill(loc))
pub fn[A] fail_with(
  message : String,
  cause : Error,
  loc~ : SourceLoc,
) -> A raise {
  raise Reraise(
    (
      (
        $|FAILED: \{message}
        $|  at \{loc}
      ),
      Some(cause),
    ),
  )
}

///|
impl Show for Reraise with output(error, logger) {
  guard error is Reraise((msg, cause))
  logger.write_string(msg + "\n")
  if cause is Some(error) {
    logger.write_string("Caused by: \{error}\n")
  }
}
