///|
/// Simple test to verify basic functionality
test "basic parsing works" {
  let toml = "name = \"test\""
  let result = parse_toml(toml)
  match result {
    Ok(doc) =>
      match doc.get("name") {
        Some(TomlValue::String(s)) => inspect(s, content="test")
        _ => assert_eq(true, false)
      }
    Err(_) => assert_eq(true, false)
  }
}

///|
/// Test integer parsing
test "integer parsing" {
  let toml = "count = 42"
  let result = parse_toml(toml)
  match result {
    Ok(doc) =>
      match doc.get("count") {
        Some(TomlValue::Integer(i)) => inspect(i, content="42")
        _ => assert_eq(true, false)
      }
    Err(_) => assert_eq(true, false)
  }
}

///|
/// Test boolean parsing
test "boolean parsing" {
  let toml = "enabled = true"
  let result = parse_toml(toml)
  match result {
    Ok(doc) =>
      match doc.get("enabled") {
        Some(TomlValue::Boolean(b)) => inspect(b, content="true")
        _ => assert_eq(true, false)
      }
    Err(_) => assert_eq(true, false)
  }
}

///|
/// Test table parsing
test "table parsing" {
  let toml =
    #|[database]
    #|host = "localhost"
    #|port = 5432
    #|
  let result = parse_toml(toml)
  match result {
    Ok(doc) =>
      match doc.get("database") {
        Some(TomlValue::Table(table)) => {
          match table.get("host") {
            Some(TomlValue::String(host)) => inspect(host, content="localhost")
            _ => assert_eq(true, false)
          }
          match table.get("port") {
            Some(TomlValue::Integer(port)) => inspect(port, content="5432")
            _ => assert_eq(true, false)
          }
        }
        _ => assert_eq(true, false)
      }
    Err(_) => assert_eq(true, false)
  }
}
