///|
enum Path {
  Opaque(String)
  Segments(Array[String])
}

///|
fn Path::shorten(self : Path) -> Unit {
  match self {
    Opaque(_) => ()
    Segments(segments) => if !segments.is_empty() { segments.pop() |> ignore() }
  }
}
