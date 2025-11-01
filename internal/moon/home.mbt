///|
fn home() -> String raise {
  if @os.getenv("MOON_HOME") is Some(moon_home) {
    return moon_home
  } else {
    let path = @path.Path::parse(@os.home(), kind=Directory)
    let path_builder = @path.PathBuilder::from_path(path)
    path_builder.add_directory(".moon")
    path_builder.to_string()
  }
}
