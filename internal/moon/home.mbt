///|
pub fn home() -> String raise {
  if @os.getenv("MOON_HOME") is Some(moon_home) {
    return moon_home
  } else {
    return @os.home() |> @path.join(".moon")
  }
}
