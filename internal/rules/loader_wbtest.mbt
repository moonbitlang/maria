///|
async test "Loader::load" (t : @test.Test) {
  @mock.run(t, mock => {
    let home = mock.cwd
    @mock.with_home(home, () => {
      home.add_json_tree({
        ".moonagent": {
          "rules": {
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
          },
        },
        "project": {
          ".moonagent": {
            "rules": {
              "c.md": (
                #|---
                #|description: This is rule C
                #|globs: ["*.txt"]
                #|alwaysApply: false
                #|---
                #|Content of rule C
              ),
            },
          },
        },
      })
      let project_path = @pathx.join(home.path(), "project")
      let rules = Loader::new(project_path, logger=mock.logger)
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
