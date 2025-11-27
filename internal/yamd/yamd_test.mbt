///|
test {
  let content =
    #|---
    #|description: This is rule A
    #|globs:
    #|alwaysApply: true
    #|---
    #|Content of rule A
  let { meta, text } = @yamd.parse(content)
  @json.inspect(meta, content={
    "description": "This is rule A",
    "globs": null,
    "alwaysApply": true,
  })
  inspect(text, content="Content of rule A")
}

///|
test {
  let content =
    #|---
    #|description: This is rule B
    #|globs: ["*.txt", "*.md"]
    #|alwaysApply: false
    #|---
    #|Content of rule B
  let { meta, text } = @yamd.parse(content)
  @json.inspect(meta, content={
    "description": "This is rule B",
    "globs": ["*.txt", "*.md"],
    "alwaysApply": false,
  })
  inspect(text, content="Content of rule B")
}

///|
test {
  let content =
    #|---
    #|description: This is rule C
    #|globs: ["*.txt"]
    #|alwaysApply: false
    #|---
    #|Content of rule C
  let { meta, text } = @yamd.parse(content)
  @json.inspect(meta, content={
    "description": "This is rule C",
    "globs": ["*.txt"],
    "alwaysApply": false,
  })
  inspect(text, content="Content of rule C")
}

///|
test {
  let content =
    #|---
    #|description: "This is a test rule"
    #|globs: ["**/*.js", "**/*.ts"]
    #|alwaysApply: true
    #|---
    #|
    #|console.log("Hello, world!");
    #|
  let { meta, text } = @yamd.parse(content)
  @json.inspect(meta, content={
    "description": "This is a test rule",
    "globs": ["**/*.js", "**/*.ts"],
    "alwaysApply": true,
  })
  inspect(
    text,
    content=(
      #|
      #|console.log("Hello, world!");
      #|
    ),
  )
}

///|
test {
  let content =
    #|# No front matter
  let { meta, text } = @yamd.parse(content)
  @json.inspect(meta, content={})
  inspect(text, content="")
}
