///|
async test "Loader::load" {
  @async.with_task_group(g => {
    let home = @mock.home("rules-loader-load")
    let home_rules = home
      .add_subdirectory(".moonagent")
      .add_directory("rules")
    let _ = home_rules.add_file(
      "a.md",
      (
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
      (
        #|---
        #|description: This is rule B
        #|globs: ["*.txt", "*.md"]
        #|alwaysApply: false
        #|---
        #|Content of rule B
      ),
    )
    g.add_defer(() => home.close())
    let project = home.add_subdirectory("project")
    let project_rules = project
      .add_directory(".moonagent")
      .add_directory("rules")
    let _ = project_rules.add_file(
      "c.md",
      (
        #|---
        #|description: This is rule C
        #|globs: ["*.txt"]
        #|alwaysApply: false
        #|---
        #|Content of rule C
      ),
    )
    g.add_defer(() => project.close())
    let logger = @pino.logger("loader-test", @pino.Transport::sink())
    g.spawn_bg(() => logger.start(), no_wait=true)
    let rules = @rules.Loader::new(project.path(), logger~)
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
}
