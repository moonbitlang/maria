///|
fn setup_tui(agent : @agent.Agent) -> Unit {
  agent.add_listener(event => match event {
    RequestCompleted(message~, ..) =>
      if message.content is Some(content) {
        println(content)
      }
    PreToolCall(tool_call) =>
      try {
        let arguments = @json.parse(tool_call.function.arguments)
        println("% \{tool_call.function.name} \{arguments.stringify(indent=2)}")
      } catch {
        _ =>
          println(
            "% \{tool_call.function.name}\n  \{tool_call.function.arguments}",
          )
      }
    PostToolCall(_, rendered~, ..) =>
      rendered.split("\n").each(text => println("> \{text}"))
    _ => ()
  })
}

///|
async fn gen_doc(
  pkg~ : @moon.PackageView,
  model? : String,
  cwd~ : String,
) -> Unit {
  let maria = @maria.Maria::new(cwd~, model?)
  setup_tui(maria.agent)
  if pkg.is_main() {
    println("Generating documentation for main package \{pkg.name()}...")
    maria.start(
      (
        $|Can you please add a README.md file documenting package \{pkg.name()}?
        $|
        $|As \{pkg.name()} is a main package, you should describe how to invoke
        $|the program defined in this package.
        $|
        $|Please DO NOT generate files in other packages and stop immediately
        $|once you have finished generating doc strings for all public interfaces in package \{pkg.name()}.
      ),
    )
  } else {
    println("Generating documentation for package \{pkg.name()}...")
    maria.start(
      (
        $|Can you please:
        $|
        $|1. Add doc strings to all public definitions in package \{pkg.name()};
        $|2. Generate a README.md file documenting package \{pkg.name()}?
        $|
        $|Please DO NOT generate files in other packages and stop immediately
        $|once you have finished generating doc strings for all public
        $|definitions in package \{pkg.name()}.
      ),
    )
  }
}

///|
async fn main {
  let args = @os.args()
  guard args is [_, .. args] else {
    println("Usage: gen/doc [--package <package>]")
    return
  }
  let mut package_ = None
  let mut model = None
  loop args {
    ["--package", p, .. args] => {
      if p.has_prefix("-") {
        println("Error: Missing package name after --package")
        return
      }
      package_ = Some(p)
      continue args
    }
    ["--model", m, .. args] => {
      if m.has_prefix("-") {
        println("Error: Missing model name after --model")
        return
      }
      model = Some(m)
      continue args
    }
    [unknown, ..] => {
      println("Error: Unknown argument \{unknown}")
      return
    }
    [] => ()
  }
  let cwd = @os.cwd()
  let moon = @moon.Module::load(cwd)
  let uuid = @uuid.generator(@rand.chacha8())
  if package_ is Some(package_) {
    let pkg = moon.find_package(package_)
    guard pkg is Some(pkg) else {
      println(
        "Error: Package \{package_} not found in the current MoonBit module.",
      )
      return
    }
    let id = uuid.v4().to_string()
    let worktree_path = cwd
      |> @path.join(".moonagent")
      |> @path.join("worktrees")
      |> @path.join(id)
    @git.add_worktree(worktree_path, new_branch="maria-\{id}", cwd~)
    gen_doc(pkg~, model?, cwd=worktree_path)
  } else {
    for pkg in moon.packages().collect() {
      let id = uuid.v4().to_string()
      let worktree_path = cwd
        |> @path.join(".moonagent")
        |> @path.join("worktrees")
        |> @path.join(id)
      @git.add_worktree(worktree_path, new_branch="maria-\{id}", cwd~)
      gen_doc(pkg~, model?, cwd=worktree_path)
    }
  }
}
