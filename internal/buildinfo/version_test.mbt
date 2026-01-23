///|
test "Version::parse" {
  let v1 = Version::parse("0.0.0")
  json_inspect(v1, content={ "major": 0, "minor": 0, "patch": 0 })
  let v2 = Version::parse("1.2.3+45.abcd1234")
  json_inspect(v2, content={
    "major": 1,
    "minor": 2,
    "patch": 3,
    "build": { "number": 45, "commit": "abcd1234" },
  })
}

///|
test "Version::compare" {
  let v1 = Version::parse("1.0.0")
  let v2 = Version::parse("1.0.1")
  let v3 = Version::parse("1.1.0")
  let v4 = Version::parse("2.0.0")
  let v5 = Version::parse("1.0.0+1.abcdef")
  let v6 = Version::parse("1.0.0+2.123456")
  json_inspect(v1 == v1, content=true)
  json_inspect(v1 < v2, content=true)
  json_inspect(v2 > v1, content=true)
  json_inspect(v2 < v3, content=true)
  json_inspect(v3 < v4, content=true)
  json_inspect(v1 < v5, content=true)
  json_inspect(v5 < v6, content=true)
}
