///|
async test "Loader::apply" (t : @test.Test) {
  @mock.run(t, mock => {
    let home = mock.cwd
    @mock.with_home(home, () => {
      let home_rules = home.add_directory(".moonagent").add_directory("rules")
      let _ = home_rules.add_file(
        "a.md",
        content=(
          #|---
          #|description: This is rule A
          #|globs:
          #|alwaysApply: true
          #|---
          #|Content of rule A
        ),
      )
      let _ = home_rules.add_file(
        "b.md",
        content=(
          #|---
          #|description: This is rule B
          #|globs: ["*.txt", "*.md"]
          #|alwaysApply: false
          #|---
          #|Content of rule B
        ),
      )
      let project = home.add_directory("project")
      let project_rules = project
        .add_directory(".moonagent")
        .add_directory("rules")
      let _ = project_rules.add_file(
        "c.md",
        content=(
          #|---
          #|description: This is rule C
          #|globs: ["*.txt"]
          #|alwaysApply: false
          #|---
          #|Content of rule C
        ),
      )
      let _ = project_rules.add_file(
        "d.md",
        content=(
          #|This is a plain text file with no front matter, the application
          #|of the rule is solely determined by the file name.
        ),
      )
      let rules = Loader::new(project.path(), logger=mock.logger)
      rules.load()
      let messages = [
        @openai.system_message(content="System message"),
        @openai.user_message(content="User message"),
        @openai.assistant_message(content="Assistant message"),
        @openai.tool_message(tool_call_id="tool_call_1", content="Tool message"),
      ]
      rules.apply(messages)
      @json.inspect(messages, content=[
        { "role": "system", "content": "System message" },
        {
          "role": "user",
          "content": "# Project Rules\n\nLoaded 4 rules from .moonagent/rules directory:\n\n## a\n\nThis is rule A\n\n- **Always Apply**: true\n- **Description**: This is rule A\n\nContent of rule A\n\n## b\n\nThis is rule B\n\n- **Always Apply**: false\n- **Globs**: [*.txt, *.md]\n- **Description**: This is rule B\n\n## c\n\nThis is rule C\n\n- **Always Apply**: false\n- **Globs**: [*.txt]\n- **Description**: This is rule C\n\n## d\n\nNo description\n\n- **Always Apply**: false\n- **Description**: No description\n",
        },
        { "role": "user", "content": "User message" },
        {
          "role": "assistant",
          "tool_calls": [],
          "content": "Assistant message",
        },
        {
          "role": "tool",
          "content": [{ "type": "text", "text": "Tool message" }],
          "tool_call_id": "tool_call_1",
        },
      ])
    })
  })
}
