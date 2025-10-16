///|
/// Example demonstrating TOML parser usage
pub fn demo() -> Unit {
  let toml_content =
    #|# This is a TOML document.
    #|
    #|title = "TOML Example"
    #|
    #|[owner]
    #|name = "Tom Preston-Werner"
    #|dob = "1979-05-27T07:32:00-08:00" # First class dates
    #|
    #|[database]
    #|server = "192.168.1.1"
    #|ports = [ 8001, 8001, 8002 ]
    #|connection_max = 5000
    #|enabled = true
    #|
  println("Parsing TOML document:")
  println("=====================")
  println(toml_content)
  println("=====================")
  match parse_toml(toml_content) {
    Ok(doc) => {
      println("✅ Parsing successful!")
      println("")

      // Access top-level values
      match doc.get("title") {
        Some(TomlValue::String(title)) => println("Title: \{title}")
        _ => ()
      }

      // Access nested values in owner table
      match doc.get("owner") {
        Some(TomlValue::Table(owner)) => {
          println("Owner information:")
          match owner.get("name") {
            Some(TomlValue::String(name)) => println("  Name: \{name}")
            _ => ()
          }
          match owner.get("dob") {
            Some(TomlValue::String(dob)) => println("  DOB: \{dob}")
            _ => ()
          }
        }
        _ => ()
      }

      // Access database configuration
      match doc.get("database") {
        Some(TomlValue::Table(db)) => {
          println("Database configuration:")
          match db.get("server") {
            Some(TomlValue::String(server)) => println("  Server: \{server}")
            _ => ()
          }
          match db.get("connection_max") {
            Some(TomlValue::Integer(max)) =>
              println("  Max connections: \{max}")
            _ => ()
          }
          match db.get("enabled") {
            Some(TomlValue::Boolean(enabled)) =>
              println("  Enabled: \{enabled}")
            _ => ()
          }
          match db.get("ports") {
            Some(TomlValue::Array(ports)) => {
              println("  Ports: [")
              for port in ports {
                match port {
                  TomlValue::Integer(p) => println("    \{p}")
                  _ => ()
                }
              }
              println("  ]")
            }
            _ => ()
          }
        }
        _ => ()
      }
    }
    Err(error) => {
      println("❌ Parsing failed:")
      println("Error: \{error}")
    }
  }
}
