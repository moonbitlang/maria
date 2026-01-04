///|
#callsite(autofill(args_loc, loc))
pub fn inspect(
  obj : &ToJason,
  content? : &ToJason,
  loc~ : SourceLoc,
  args_loc~ : ArgsLoc,
) -> Unit raise InspectError {
  let loc = loc.to_json_string()
  let args_loc = args_loc.to_json()
  let actual = obj.to_jason().stringify(escape_slash=false)
  let want = match content {
    None => "".to_json().stringify(escape_slash=false)
    Some(x) => x.to_jason().stringify(escape_slash=false)
  }
  if actual != want {
    raise InspectError(
      "@EXPECT_FAILED {\"loc\": \{loc}, \"args_loc\": \{args_loc}, \"expect\": \{want.escape()}, \"actual\": \{actual.escape()}, \"mode\": \"json\"}",
    )
  }
}
