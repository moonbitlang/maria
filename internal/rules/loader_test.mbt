///|
async test "Loader::load" (t : @test.Test) {
  @mock.run(t, taco => {
    let home = taco.cwd
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
      let rules = @rules.Loader::new(project.path(), logger=taco.logger)
      rules.load()
      inspect(
        rules.format(),
        content=(
          #|# Project Rules
          #|
          #|Loaded 3 rules from .moonagent/rules directory:
          #|
          #|## a
          #|
          #|This is rule A
          #|
          #|- **Always Apply**: true
          #|- **Description**: This is rule A
          #|
          #|Content of rule A
          #|
          #|## b
          #|
          #|This is rule B
          #|
          #|- **Always Apply**: false
          #|- **Globs**: [*.txt, *.md]
          #|- **Description**: This is rule B
          #|
          #|## c
          #|
          #|This is rule C
          #|
          #|- **Always Apply**: false
          #|- **Globs**: [*.txt]
          #|- **Description**: This is rule C
          #|
        ),
      )
    })
  })
}
