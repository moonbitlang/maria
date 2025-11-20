///|
pub struct OriginFormRequestTarget {
  segments : Array[StringView]
  query : StringView?
} derive(ToJson)

///|
pub enum RequestTarget {
  Origin(OriginFormRequestTarget)
  Asterisk
}

///|
pub fn OriginFormRequestTarget::parse(
  input : StringView,
) -> OriginFormRequestTarget {
  let mut last = input
  let segments = []
  loop input.view() {
    ['?', .. query] => OriginFormRequestTarget::{ segments, query: Some(query) }
    ['/', .. rest] as view => {
      segments.push(
        input
        .data()
        .view(start_offset=last.start_offset(), end_offset=view.start_offset()),
      )
      last = rest
      continue rest
    }
    [_, .. rest] => continue rest
    [] => {
      segments.push(input.data().view(start_offset=last.start_offset()))
      OriginFormRequestTarget::{ segments, query: None }
    }
  }
}

///|
pub fn RequestTarget::parse(input : StringView) -> RequestTarget? {
  match input {
    ['/', .. rest] => Some(Origin(OriginFormRequestTarget::parse(rest)))
    ['*'] => Some(Asterisk)
    _ => None
  }
}
