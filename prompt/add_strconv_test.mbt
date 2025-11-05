///|
async test "add_strconv" (t : @test.T) {
  @mock.run(t, mock => {
    mock.add_files([
      ("moon.pkg.json", Json::object({ "is_main": true }).stringify(indent=2)),
      (
        "moon.mod.json",
        Json::object({ "name": "username/example", "version": "0.1.0" }).stringify(
          indent=2,
        ),
      ),
      (
        "main.mbt",
        (
          #|///|
          #|fn main {
          #|  let args = @env.args()
          #|  let num_str = args[1]
          #|  let num : Int = { ... }
          #|  println(num.to_json().stringify())
          #|}
        ),
      ),
    ])
    let api_key = mock.getenv("OPENAI_API_KEY")
    let model = @model.open_router_model(api_key~, name=Qwen3CoderPlus)
    let agent = @agent.new(model, logger=mock.logger, cwd=mock.cwd.path())
    let job_manager = @job.Manager::new(cwd=agent.cwd)
    let file_manager = @file.manager(cwd=agent.cwd)
    agent.add_tools([
      @execute_command.new(job_manager).to_agent_tool(),
      @list_files.new(file_manager).to_agent_tool(),
      @read_file.new(file_manager).to_agent_tool(),
      @search_files.new(agent.cwd).to_agent_tool(),
      @replace_in_file.new(file_manager).to_agent_tool(),
    ])
    let system_prompt = [@prompt.prelude, @prompt.moonbit, @search_files.prompt].join(
      "\n",
    )
    let system_message = @openai.system_message(content=system_prompt)
    agent.add_message(system_message)
    agent.add_message(
      @openai.user_message(
        content=(
          #|Can you please use the strconv package from standard library to convert the string `num_str` to an integer `num` in the `main` function in `main.mbt`?
        ),
      ),
    )
    agent.start()
    let moon = @moon.Module::load(mock.cwd.path())
    moon.check()
    let (status, stdout) = moon.run(".", ["12345"])
    @json.inspect(status, content=0)
    inspect(
      stdout,
      content=(
        #|12345
        #|
      ),
    )
  })
}
