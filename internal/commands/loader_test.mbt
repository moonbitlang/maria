///|
async test "Loader::load" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      ".moonagent": {
        "commands": {
          "greet.md": (
            #|---
            #|description: "Greet someone"
            #|---
            #|
            #|Please greet the user warmly and ask how you can help them today.
          ),
          "deploy.md": (
            #|---
            #|description: "Deploy an application"
            #|---
            #|
            #|You should help the user deploy their application. Ask them about:
            #|- Target environment
            #|- Version to deploy
            #|- Any special configuration needed
          ),
        },
      },
      "cwd": {
        ".moonagent": {
          "commands": {
            "local-cmd.md": (
              #|---
              #|description: "A local command"
              #|---
              #|
              #|This is a project-specific command that provides local context.
            ),
          },
        },
      },
    })
    let home = mock.cwd.path()
    let cwd = @pathx.join(home, "cwd")
    let loader = Loader::new(home~, cwd~)
    // Load commands
    loader.load()
    let cmds = loader.commands()
    inspect(cmds.length(), content="3")
    @json.inspect(mock.json(cmds["greet"]), content={
      "name": "greet",
      "description": "Greet someone",
      "content": "\nPlease greet the user warmly and ask how you can help them today.",
      "location": "(mock:cwd)/.moonagent/commands/greet.md",
    })
    @json.inspect(mock.json(cmds["deploy"]), content={
      "name": "deploy",
      "description": "Deploy an application",
      "content": "\nYou should help the user deploy their application. Ask them about:\n- Target environment\n- Version to deploy\n- Any special configuration needed",
      "location": "(mock:cwd)/.moonagent/commands/deploy.md",
    })
    @json.inspect(mock.json(cmds["local-cmd"]), content={
      "name": "local-cmd",
      "description": "A local command",
      "content": "\nThis is a project-specific command that provides local context.",
      "location": "(mock:cwd)/cwd/.moonagent/commands/local-cmd.md",
    })
  })
}

///|
async test "Loader::load/empty" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      ".moonagent": { "commands": {} },
      "cwd": { ".moonagent": { "commands": {} } },
    })
    let home = mock.cwd.path()
    let cwd = @pathx.join(home, "cwd")
    let loader = Loader::new(home~, cwd~)
    loader.load()
    let cmds = loader.commands()
    inspect(cmds.length(), content="0")
  })
}

///|
async test "Loader::get_command" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      ".moonagent": {
        "commands": {
          "greet.md": (
            #|---
            #|description: "Greet someone"
            #|---
            #|
            #|Please greet the user warmly.
          ),
        },
      },
    })
    let home = mock.cwd.path()
    let cwd = @pathx.join(home, "cwd")
    let loader = Loader::new(home~, cwd~)
    loader.load()
    let cmd = loader.get_command("greet")
    @json.inspect(mock.json(cmd), content=[
      {
        "name": "greet",
        "description": "Greet someone",
        "content": "\nPlease greet the user warmly.",
        "location": "(mock:cwd)/.moonagent/commands/greet.md",
      },
    ])
    let nonexistent = loader.get_command("nonexistent")
    inspect(nonexistent, content="None")
  })
}

///|
async test "Loader::load/invalid-command" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      ".moonagent": {
        "commands": {
          "valid.md": (
            #|---
            #|description: "Valid command"
            #|---
            #|Content
          ),
          "invalid.md": (
            #|---
            #|description: 123
            #|---
            #|This has an invalid frontmatter
          ),
        },
      },
    })
    let home = mock.cwd.path()
    let cwd = @pathx.join(home, "cwd")
    let loader = Loader::new(home~, cwd~)
    loader.load()
    let cmds = loader.commands()
    // Invalid command should be skipped
    inspect(cmds.length(), content="1")
    @json.inspect(mock.json(cmds), content={
      "valid": {
        "name": "valid",
        "description": "Valid command",
        "content": "Content",
        "location": "(mock:cwd)/.moonagent/commands/valid.md",
      },
    })
  })
}

///|
async test "Loader::reload" (t : @test.Test) {
  @mock.run(t, mock => {
    let commands_dir = mock
      .add_directory(".moonagent")
      .add_directory("commands")
    let greet_file = commands_dir.add_file("greet.md")
    greet_file.write_string(
      (
        #|---
        #|description: "Greet someone"
        #|---
        #|
        #|Please greet the user.
      ),
    )
    let home = mock.cwd.path()
    let cwd = @pathx.join(home, "cwd")
    let loader = Loader::new(home~, cwd~)
    loader.load()
    let cmds = loader.commands()
    inspect(cmds.length(), content="1")
    // Update the command
    greet_file.write_string(
      (
        #|---
        #|description: "Updated greet command"
        #|---
        #|
        #|Please greet the user warmly and enthusiastically!
      ),
    )
    // Add a new command
    commands_dir.add_files({
      "deploy.md": (
        #|---
        #|description: "Deploy application"
        #|---
        #|
        #|Help the user deploy their application.
      ),
    })
    loader.load()
    let updated_cmds = loader.commands()
    inspect(updated_cmds.length(), content="2")
    @json.inspect(mock.json(updated_cmds["greet"]), content={
      "name": "greet",
      "description": "Updated greet command",
      "content": "\nPlease greet the user warmly and enthusiastically!",
      "location": "(mock:cwd)/.moonagent/commands/greet.md",
    })
  })
}

///|
async test "Loader::load/no-frontmatter" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      ".moonagent": {
        "commands": {
          "simple.md": (
            #|# Simple command
            #|
            #|This has no frontmatter.
          ),
        },
      },
    })
    let home = mock.cwd.path()
    let cwd = @pathx.join(home, "cwd")
    let loader = Loader::new(home~, cwd~)
    loader.load()
    let cmds = loader.commands()
    inspect(cmds.length(), content="1")
    let cmd = cmds["simple"]
    @json.inspect(mock.json(cmd), content={
      "name": "simple",
      "content": "",
      "location": "(mock:cwd)/.moonagent/commands/simple.md",
    })
  })
}

///|
async test "Loader::load/non-md-files-ignored" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      ".moonagent": {
        "commands": {
          "valid.md": (
            #|---
            #|description: "Valid"
            #|---
            #|Content
          ),
          "readme.txt": "This should be ignored",
          "config.json": "{}",
        },
      },
    })
    let home = mock.cwd.path()
    let cwd = @pathx.join(home, "cwd")
    let loader = Loader::new(home~, cwd~)
    loader.load()
    let cmds = loader.commands()
    inspect(cmds.length(), content="1")
    @json.inspect(mock.json(cmds), content={
      "valid": {
        "name": "valid",
        "description": "Valid",
        "content": "Content",
        "location": "(mock:cwd)/.moonagent/commands/valid.md",
      },
    })
  })
}

///|
async test "Loader::load/parent-directories" (t : @test.Test) {
  @mock.run(t, mock => {
    // Directory layout:
    // (home)
    //   .moonagent/commands/global.md
    //   project/.moonagent/commands/project.md
    //   project/sub/.moonagent/commands/sub.md
    //   project/sub/deep (cwd)
    // and `project` is marked as a git repo root.
    mock.add_json_tree({
      ".moonagent": {
        "commands": {
          "global.md": (
            #|---
            #|description: "Global command"
            #|---
            #|Global instructions.
          ),
        },
      },
      "project": {
        ".git": {},
        ".moonagent": {
          "commands": {
            "project.md": (
              #|---
              #|description: "Project command"
              #|---
              #|Project instructions.
            ),
          },
        },
        "sub": {
          ".moonagent": {
            "commands": {
              "sub.md": (
                #|---
                #|description: "Sub command"
                #|---
                #|Sub instructions.
              ),
            },
          },
          "deep": {},
        },
      },
    })
    let home = mock.cwd.path()
    let cwd = @pathx.join(home, "project/sub/deep")
    let loader = Loader::new(home~, cwd~)
    loader.load()
    @json.inspect(mock.json(loader.commands()), content={
      "global": {
        "name": "global",
        "description": "Global command",
        "content": "Global instructions.",
        "location": "(mock:cwd)/.moonagent/commands/global.md",
      },
      "project": {
        "name": "project",
        "description": "Project command",
        "content": "Project instructions.",
        "location": "(mock:cwd)/project/.moonagent/commands/project.md",
      },
      "sub": {
        "name": "sub",
        "description": "Sub command",
        "content": "Sub instructions.",
        "location": "(mock:cwd)/project/sub/.moonagent/commands/sub.md",
      },
    })
  })
}

///|
async test "Loader::load/no-git-loads-cwd-and-home" (t : @test.Test) {
  @mock.run(t, mock => {
    // Directory layout:
    // (home)
    //   .moonagent/commands/global.md
    //   cwd/.moonagent/commands/local.md
    // and there is NO `.git` anywhere.
    mock.add_json_tree({
      ".moonagent": {
        "commands": {
          "global.md": (
            #|---
            #|description: "Global command"
            #|---
            #|Global instructions.
          ),
        },
      },
      "cwd": {
        ".moonagent": {
          "commands": {
            "local.md": (
              #|---
              #|description: "Local command"
              #|---
              #|Local instructions.
            ),
          },
        },
      },
    })
    let home = mock.cwd.path()
    let cwd = @pathx.join(home, "cwd")
    let loader = Loader::new(home~, cwd~)
    loader.load()
    @json.inspect(mock.json(loader.commands()), content={
      "global": {
        "name": "global",
        "description": "Global command",
        "content": "Global instructions.",
        "location": "(mock:cwd)/.moonagent/commands/global.md",
      },
      "local": {
        "name": "local",
        "description": "Local command",
        "content": "Local instructions.",
        "location": "(mock:cwd)/cwd/.moonagent/commands/local.md",
      },
    })
  })
}
