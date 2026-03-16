///|
fn regexp_search_all(
  regex : @regexp.Regexp,
  input : StringView,
) -> Array[StringView] {
  let tokens : Array[StringView] = []
  let mut remaining = input
  while remaining.length() > 0 {
    let regex_result = regex.execute(remaining)
    let before = regex_result.before()
    if !before.is_empty() {
      tokens.push(before)
    }
    remaining = remaining[before.length():]
    if regex_result.matched() {
      let m = if !regex_result.groups().contains("Assertion") {
        regex_result.results()[0].unwrap()
      } else {
        let m = regex_result.results()[0].unwrap()
        m[0:m.length() - 1]
      }
      tokens.push(m)
      remaining = remaining[m.length():]
    } else {
      tokens.push(remaining[0:1])
      remaining = remaining[1:]
    }
  }
  tokens
}
