///|
test "parse_skill_from_content" {
  let content =
    #|---
    #|name: pdf-processing
    #|description: Extract text and tables from PDF files.
    #|license: Apache-2.0
    #|compatibility: Requires `moon`
    #|allowed-tools:
    #|  - execute_command
    #|metadata:
    #|  author: example-org
    #|  version: "1.0"
    #|---
    #|
    #|Use this skill to handle PDFs.
  let skill = parse_skill_from_content(
    content,
    directory="pdf-processing",
    location="/tmp/skill/SKILL.md",
  )
  @json.inspect(skill, content={
    "name": "pdf-processing",
    "description": "Extract text and tables from PDF files.",
    "license": "Apache-2.0",
    "compatibility": "Requires `moon`",
    "allowed_tools": ["execute_command"],
    "metadata": { "author": "example-org", "version": "1.0" },
    "location": "/tmp/skill/SKILL.md",
  })
}

///|
test "parse_skill_from_content/space-delimited-allowed-tools" {
  let content =
    #|---
    #|name: sample-skill
    #|description: A sample skill.
    #|allowed-tools: tool1 tool2 tool3
    #|---
    #|
    #|This is a sample skill.
  let skill = parse_skill_from_content(
    content,
    directory="sample-skill",
    location="/tmp/skill/SKILL.md",
  )
  @json.inspect(skill, content={
    "name": "sample-skill",
    "description": "A sample skill.",
    "allowed_tools": ["tool1", "tool2", "tool3"],
    "location": "/tmp/skill/SKILL.md",
  })
}

///|
test "parse_skill_from_content/invalid-allowed-tools" {
  let content =
    #|---
    #|name: sample-skill
    #|description: A sample skill.
    #|allowed-tools:
    #|  tool1: true
    #|  tool2: false
    #|---
    #|
    #|This is a sample skill.
  let result = try? parse_skill_from_content(
    content,
    directory="sample-skill",
    location="/tmp/skill/SKILL.md",
  )
  @json.inspect(result, content={
    "Err": [
      "SkillFormatError", "Field 'allowed-tools' must be a space-delimited string or array of strings, got {\"tool1\":true,\"tool2\":false}",
    ],
  })
}

///|
test "parse_skill_from_content/empty-description" {
  let content =
    #|---
    #|name: invalid-skill
    #|description: ""
    #|---
    #|
    #|This skill has an invalid description.
  let result = try? parse_skill_from_content(
    content,
    directory="invalid-skill",
    location="/tmp/skill/SKILL.md",
  )
  @json.inspect(result, content={
    "Err": [
      "SkillFormatError", "Field 'description' must be a non-empty string",
    ],
  })
}

///|
test "parse_skill_from_content/invalid-name" {
  let content =
    #|---
    #|name: invalid--name
    #|description: A skill with invalid name.
    #|---
    #|
    #|This skill has an invalid name.
  let result = try? parse_skill_from_content(
    content,
    directory="invalid--name",
    location="/tmp/skill/SKILL.md",
  )
  @json.inspect(result, content={
    "Err": ["SkillFormatError", "Skill name cannot contain consecutive hyphens"],
  })
}

///|
test "parse_skill_from_content/name-mismatches-directory" {
  let content =
    #|---
    #|name: mismatch-directory
    #|description: A skill with mismatched directory name.
    #|---
    #|
    #|This skill has a mismatched directory name.
  let result = try? parse_skill_from_content(
    content,
    directory="different-directory",
    location="/tmp/skill/SKILL.md",
  )
  @json.inspect(result, content={
    "Err": ["SkillFormatError", "Directory name must match skill name"],
  })
}

///|
test "parse_skill_from_content/long-name" {
  let long_skill_name = "skill-name-is-way-too-long-because-it-exceeds-the-sixty-four-character-limit-imposed"
  let content =
    $|---
    $|name: \{long_skill_name}
    $|description: A skill with a name that is too long.
    $|---
    $|
    $|This skill has a name that is too long.
  let result = try? parse_skill_from_content(
    content,
    directory=long_skill_name,
    location="/tmp/skill/SKILL.md",
  )
  @json.inspect(result, content={
    "Err": ["SkillFormatError", "Skill name exceeds 64 character limit"],
  })
}

///|
test "parse_skill_from_content/long-description" {
  let long_description = "A".repeat(1025)
  let content =
    $|---
    $|name: long-description-skill
    $|description: \{long_description}
    $|---
    $|
    $|This skill has a description that is too long.
  let result = try? parse_skill_from_content(
    content,
    directory="long-description-skill",
    location="/tmp/skill/SKILL.md",
  )
  @json.inspect(result, content={
    "Err": ["SkillFormatError", "Description exceeds 1024 character limit"],
  })
}

///|
test "parse_skill_from_content/empty-name" {
  let content =
    #|---
    #|name: ""
    #|description: A skill with an empty name.
    #|---
    #|
    #|This skill has an empty name.
  let result = try? parse_skill_from_content(
    content,
    directory="",
    location="/tmp/skill/SKILL.md",
  )
  @json.inspect(result, content={
    "Err": ["SkillFormatError", "Field 'name' must be a non-empty string"],
  })
}

///|
test "parse_skill_from_content/name-starts-with-hyphen" {
  let content =
    #|---
    #|name: -invalidname
    #|description: A skill with a name that starts with a hyphen.
    #|---
    #|
    #|This skill has a name that starts with a hyphen.
  let result = try? parse_skill_from_content(
    content,
    directory="-invalidname",
    location="/tmp/skill/SKILL.md",
  )
  @json.inspect(result, content={
    "Err": ["SkillFormatError", "Skill name cannot start or end with a hyphen"],
  })
}

///|
test "parse_skill_from_content/name-ends-with-hyphen" {
  let content =
    #|---
    #|name: invalidname-
    #|description: A skill with a name that ends with a hyphen.
    #|---
    #|
    #|This skill has a name that ends with a hyphen.
  let result = try? parse_skill_from_content(
    content,
    directory="invalidname-",
    location="/tmp/skill/SKILL.md",
  )
  @json.inspect(result, content={
    "Err": ["SkillFormatError", "Skill name cannot start or end with a hyphen"],
  })
}

///|
test "parse_skill_from_content/missing-name" {
  let content =
    #|---
    #|description: A skill missing the name field.
    #|---
    #|
    #|This skill is missing the name field.
  let result = try? parse_skill_from_content(
    content,
    directory="missing-name",
    location="/tmp/skill/SKILL.md",
  )
  @json.inspect(result, content={
    "Err": ["SkillFormatError", "Missing field 'name'"],
  })
}

///|
test "parse_skill_from_content/missing-description" {
  let content =
    #|---
    #|name: missing-description
    #|---
    #|
    #|This skill is missing the description field.
  let result = try? parse_skill_from_content(
    content,
    directory="missing-description",
    location="/tmp/skill/SKILL.md",
  )
  @json.inspect(result, content={
    "Err": ["SkillFormatError", "Missing field 'description'"],
  })
}

///|
test "parse_skill_from_content/missing-frontmatter" {
  let content =
    #|This skill file is missing frontmatter.
  let result = try? parse_skill_from_content(
    content,
    directory="missing-frontmatter",
    location="/tmp/skill/SKILL.md",
  )
  @json.inspect(result, content={
    "Err": ["SkillFormatError", "Missing field 'name'"],
  })
}

///|
test "parse_skill_from_content/non-string-name" {
  let content =
    #|---
    #|name: 12345
    #|description: A skill with a non-string name.
    #|---
    #|
    #|This skill has a non-string name.
  let result = try? parse_skill_from_content(
    content,
    directory="12345",
    location="/tmp/skill/SKILL.md",
  )
  @json.inspect(result, content={
    "Err": ["SkillFormatError", "Field 'name' must be a string, got 12345"],
  })
}

///|
test "parse_skill_from_content/non-string-description" {
  let content =
    #|---
    #|name: non-string-description
    #|description: 67890
    #|---
    #|
    #|This skill has a non-string description.
  let result = try? parse_skill_from_content(
    content,
    directory="non-string-description",
    location="/tmp/skill/SKILL.md",
  )
  @json.inspect(result, content={
    "Err": [
      "SkillFormatError", "Field 'description' must be a string, got 67890",
    ],
  })
}
