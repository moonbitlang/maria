///|
async test "maria/resume" (t : @test.Test) {
  @mock.run(t, mock => {
    let cwd = mock.cwd
    let model = mock.model(name=ClaudeHaiku4_5)
    let id = {
      let maria = @maria.Maria::new(
        model~,
        home=cwd.path(),
        cwd=cwd.path(),
        user_message="Hello, please call me Mr. Rabbit.",
      )
      defer maria.close()
      let id = maria.agent.id()
      maria.start()
      id
    }
    let mut result = None
    let maria = @maria.resume_(
      model~,
      home=cwd.path(),
      id,
      user_message="What is my name? Please use the <submit_user_name/> tool to submit my name.",
    )
    maria.agent.add_tool(
      @tool.new(
        name="submit_user_name",
        description="Submit the user's name.",
        schema=@tool.JsonSchema::from_json({
          "type": "object",
          "properties": { "name": { "type": "string" } },
          "required": ["name"],
        }),
        ToolFn(args => {
          guard args is { "name": String(name), .. } else {
            return @tool.error("Invalid arguments")
          }
          result = Some(name)
          @tool.ok("Name submitted successfully")
        }),
      ),
    )
    maria.start()
    json_inspect(
      result is Some(content) && content.contains("Rabbit"),
      content=true,
    )
  })
}
