///|
test "meta_write_to_file tool is properly defined" {
  // Test that the tool has the correct name and description
  inspect(meta_write_to_file.name, content="meta_write_to_file")

  // Test that the description contains key phrases
  let desc = meta_write_to_file.description
  let has_enhanced = desc.contains("Enhanced file writing tool")
  let has_formatting = desc.contains("formats MoonBit files")
  let has_syntax_check = desc.contains("checks for syntax errors")
  let has_subagent = desc.contains("spawns a sub-agent")
  inspect(has_enhanced, content="true")
  inspect(has_formatting, content="true")
  inspect(has_syntax_check, content="true")
  inspect(has_subagent, content="true")
}

///|
test "meta_write_to_file tool parameters are correctly defined" {
  // Test that required parameters are defined
  let params = meta_write_to_file.parameters

  // Check that it has the correct type
  match params["type"] {
    "object" => inspect(true, content="true")
    _ => fail("Expected parameters type to be 'object'")
  }

  // Check that required fields include path and description
  match params["required"] {
    Array(required_fields) => {
      let mut has_path = false
      let mut has_description = false
      for field in required_fields {
        if field == "path" {
          has_path = true
        }
        if field == "description" {
          has_description = true
        }
      }
      inspect(has_path, content="true")
      inspect(has_description, content="true")
    }
    _ => fail("Expected required to be an array")
  }
}
