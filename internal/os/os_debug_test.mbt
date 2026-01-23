///|
test "executable" {
  let executable = @os.executable()
  let tcc_path = @moon.home()
    |> @pathx.join("bin")
    |> @pathx.join("internal")
    |> @pathx.join("tcc")
  json_inspect(executable == tcc_path, content=true)
}
