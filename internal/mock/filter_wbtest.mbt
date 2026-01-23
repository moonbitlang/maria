///|
test "Filter::string replacements" {
  let filter = Filter::new()
  filter.add("cwd", "/tmp/project")
  filter.add("token", "SECRET")
  let filtered = filter.apply_string(
    "Paths: /tmp/project and token SECRET; again /tmp/project.",
  )
  inspect(
    filtered,
    content="Paths: (mock:cwd) and token (mock:token); again (mock:cwd).",
  )
}

///|
test "Filter::json masks nested keys and values" {
  let filter = Filter::new()
  filter..add("home", "/Users/mock")..add("api", "XYZ")
  let filtered = filter.apply_json(
    Json::object({
      "path": "/Users/mock/config",
      "/Users/mock": "XYZ",
      "nested": ["XYZ", { "/Users/mock": Json::string("XYZ") }],
      "count": 1,
    }),
  )
  json_inspect(filtered, content={
    "path": "(mock:home)/config",
    "(mock:home)": "(mock:api)",
    "nested": ["(mock:api)", { "(mock:home)": "(mock:api)" }],
    "count": 1,
  })
}

///|
test "Filter::honors insertion order" {
  let filter = Filter::new()
  filter..add("long", "/tmp/project/data")..add("short", "/tmp/project")
  let filtered = filter.apply_string("/tmp/project/data/output.log")
  inspect(filtered, content="(mock:long)/output.log")
}

///|
async test "Context::json uses filter" (t : @test.Test) {
  run(t, ctx => {
    let cwd = ctx.cwd.path()
    let payload : Map[String, Json] = {}
    payload[cwd] = Json::string(cwd)
    payload["items"] = Json::array([
      Json::string(cwd),
      Json::object({ "cwd": Json::string(cwd) }),
    ])
    let filtered = ctx.json(Json::object(payload))
    json_inspect(filtered, content={
      "(mock:cwd)": "(mock:cwd)",
      "items": ["(mock:cwd)", { "cwd": "(mock:cwd)" }],
    })
  })
}
