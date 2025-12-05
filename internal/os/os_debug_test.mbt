///|
test "executable" {
  let executable = @os.executable()
  let tcc_path = @moon.home()
    |> @path.join("bin")
    |> @path.join("internal")
    |> @path.join("tcc")
  @json.inspect(executable == tcc_path, content=true)
}
