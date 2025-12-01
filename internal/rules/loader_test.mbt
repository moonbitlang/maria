///|
async test "Loader::apply" (t : @test.Test) {
  @mock.run(t, mock => {
    let home = mock.cwd
    @mock.with_home(home, () => {
      let home_rules = home.add_directory(".moonagent").add_directory("rules")
      home_rules.add_files({
        "a.md": (
          #|---
          #|description: This is rule A
          #|globs:
          #|alwaysApply: true
          #|---
          #|Content of rule A
        ),
        "b.md": (
          #|---
          #|description: This is rule B
          #|globs: ["*.txt", "*.md"]
          #|alwaysApply: false
          #|---
          #|Content of rule B
        ),
      })
      let project = home.add_directory("project")
      let project_rules = project
        .add_directory(".moonagent")
        .add_directory("rules")
      project_rules.add_files({
        "c.md": (
          #|---
          #|description: This is rule C
          #|globs: ["*.txt"]
          #|alwaysApply: false
          #|---
          #|Content of rule C
        ),
        "d.md": (
          #|This is a plain text file with no front matter, the application
          #|of the rule is solely determined by the file name.
        ),
      })
      let rules = Loader::new(project.path(), logger=mock.logger)
      // Load rules
      rules.load()
      let messages = [
        @ai.system_message(content="System message"),
        @ai.user_message(content="User message"),
        @ai.assistant_message(content="Assistant message"),
        @ai.tool_message(tool_call_id="tool_call_1", content="Tool message"),
      ]
      rules.apply(messages)
      inspect(
        messages.length(),
        content="5",
      )
    })
  })
}
