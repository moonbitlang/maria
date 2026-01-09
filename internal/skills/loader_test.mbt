///|
async test "load" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      ".moonagent": {
        "skills": {
          "pdf-processing": {
            "SKILL.md": (
              #|---
              #|name: pdf-processing
              #|description: A skill to process PDF documents.
              #|version: 1.0.0
              #|---
              #|
              #|Use this skill to extract text from PDF files.
            ),
          },
        },
      },
      "cwd": {
        ".git": {},
        ".moonagent": {
          "skills": {
            "text-summarization": {
              "SKILL.md": (
                #|---
                #|name: text-summarization
                #|description: A skill to summarize text documents.
                #|version: 1.0.0
                #|---
                #|
                #|Use this skill to generate summaries of text content.
              ),
            },
          },
        },
      },
    })
    let home = mock.cwd.path()
    let cwd = @pathx.join(home, "cwd")
    let loader = @skills.Loader::new(home~, cwd~)
    loader.load()
    @json.inspect(mock.json(loader.skills()), content={
      "moonbit-agent-guide": {
        "name": "moonbit-agent-guide",
        "description": "Guide for writing, refactoring, and testing MoonBit projects. Use when working in MoonBit modules or packages, organizing MoonBit files, using moon tooling (build/check/test/doc/ide), or following MoonBit-specific layout, documentation, and testing conventions.",
        "allowed_tools": [],
        "location": "(mock:cwd)/.moonagent/skills/.system/moonbit-agent-guide/SKILL.md",
      },
      "pdf-processing": {
        "name": "pdf-processing",
        "description": "A skill to process PDF documents.",
        "allowed_tools": [],
        "location": "(mock:cwd)/.moonagent/skills/pdf-processing/SKILL.md",
      },
      "text-summarization": {
        "name": "text-summarization",
        "description": "A skill to summarize text documents.",
        "allowed_tools": [],
        "location": "(mock:cwd)/cwd/.moonagent/skills/text-summarization/SKILL.md",
      },
    })
    let messages = [
      @ai.system_message(content="You are an AI assistant."),
      @ai.user_message(content="Please help me process this PDF document."),
    ]
    loader.load_and_apply(messages)
    guard messages is [System(content), ..] else {
      fail(
        "Messages have wrong structure, expecting [System(content), ..], got \{messages.to_json().stringify(indent=2)}",
      )
    }
    inspect(
      mock.text(content),
      content=(
        #|You are an AI assistant.
        #|
        #|====
        #|
        #|SKILLS
        #|
        #|You are equipped with skill capabilities that you can use to solve many
        #|tasks. A skill is a folder containing a SKILL.md file. This file includes:
        #|
        #|- name: The name of the skill
        #|- description: A brief description of what the skill does
        #|- location: The location of the skill on disk
        #|- instructions (as the main body): Instructions on how to use the skill.
        #|
        #|Optionally, a skill folder may also contain:
        #|
        #|- scripts: Python/Shell/... scripts for common operations
        #|- references: Reference materials such as documentation, cheat sheets,
        #|  etc.
        #|- templates: Code templates/snippets for common patterns
        #|
        #|Here is an example layout of a skill folder:
        #|
        #|```plaintext
        #|skills/
        #|  my-skill/
        #|    SKILL.md
        #|    scripts/
        #|      helper.py
        #|    references/
        #|      doc.md
        #|    templates/
        #|      snippet.mbt
        #|```
        #|
        #|To use skills efficiently, you should follow a progressive approach to
        #|discover, load and apply skills to tasks. Usually, this means:
        #|
        #|1. First, You should identify relevant skills for the task from the
        #|available skills list below.
        #|
        #|2. Next, You should load the identified skills into your working context,
        #|by reading their SKILL.md files. Note that you probably want to defer
        #|the loading of resources such as scripts, references, templates until they
        #|are actually needed.
        #|
        #|3. Finally, you should utilize the knowledge/rules/instructions provided
        #|by the loaded SKILL.md files to assist in completing the task. Optionally
        #|you may want to leverage the scripts/templates/references provided by
        #|the skill folders to accomplish the task.
        #|<available_skills>
        #|  <skill>
        #|    <name>moonbit-agent-guide</name>
        #|    <description>Guide for writing, refactoring, and testing MoonBit projects. Use when working in MoonBit modules or packages, organizing MoonBit files, using moon tooling (build/check/test/doc/ide), or following MoonBit-specific layout, documentation, and testing conventions.</description>
        #|    <location>(mock:cwd)/.moonagent/skills/.system/moonbit-agent-guide/SKILL.md</location>
        #|  </skill>
        #|  <skill>
        #|    <name>pdf-processing</name>
        #|    <description>A skill to process PDF documents.</description>
        #|    <location>(mock:cwd)/.moonagent/skills/pdf-processing/SKILL.md</location>
        #|  </skill>
        #|  <skill>
        #|    <name>text-summarization</name>
        #|    <description>A skill to summarize text documents.</description>
        #|    <location>(mock:cwd)/cwd/.moonagent/skills/text-summarization/SKILL.md</location>
        #|  </skill>
        #|</available_skills>
      ),
    )
  })
}

///|
async test "load/empty" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      ".moonagent": { "skills": {} },
      "cwd": { ".git": {}, ".moonagent": { "skills": {} } },
    })
    let home = mock.cwd.path()
    let cwd = @pathx.join(home, "cwd")
    let loader = @skills.Loader::new(home~, cwd~)
    loader.load()
    let messages = [
      @ai.system_message(content="You are an AI assistant."),
      @ai.user_message(content="Please help me process this PDF document."),
    ]
    loader.load_and_apply(messages)
    guard messages is [System(content), ..] else {
      fail(
        "Messages have wrong structure, expecting [System(content), ..], got \{messages.to_json().stringify(indent=2)}",
      )
    }
    inspect(
      mock.text(content),
      content=(
        #|You are an AI assistant.
        #|
        #|====
        #|
        #|SKILLS
        #|
        #|You are equipped with skill capabilities that you can use to solve many
        #|tasks. A skill is a folder containing a SKILL.md file. This file includes:
        #|
        #|- name: The name of the skill
        #|- description: A brief description of what the skill does
        #|- location: The location of the skill on disk
        #|- instructions (as the main body): Instructions on how to use the skill.
        #|
        #|Optionally, a skill folder may also contain:
        #|
        #|- scripts: Python/Shell/... scripts for common operations
        #|- references: Reference materials such as documentation, cheat sheets,
        #|  etc.
        #|- templates: Code templates/snippets for common patterns
        #|
        #|Here is an example layout of a skill folder:
        #|
        #|```plaintext
        #|skills/
        #|  my-skill/
        #|    SKILL.md
        #|    scripts/
        #|      helper.py
        #|    references/
        #|      doc.md
        #|    templates/
        #|      snippet.mbt
        #|```
        #|
        #|To use skills efficiently, you should follow a progressive approach to
        #|discover, load and apply skills to tasks. Usually, this means:
        #|
        #|1. First, You should identify relevant skills for the task from the
        #|available skills list below.
        #|
        #|2. Next, You should load the identified skills into your working context,
        #|by reading their SKILL.md files. Note that you probably want to defer
        #|the loading of resources such as scripts, references, templates until they
        #|are actually needed.
        #|
        #|3. Finally, you should utilize the knowledge/rules/instructions provided
        #|by the loaded SKILL.md files to assist in completing the task. Optionally
        #|you may want to leverage the scripts/templates/references provided by
        #|the skill folders to accomplish the task.
        #|<available_skills>
        #|  <skill>
        #|    <name>moonbit-agent-guide</name>
        #|    <description>Guide for writing, refactoring, and testing MoonBit projects. Use when working in MoonBit modules or packages, organizing MoonBit files, using moon tooling (build/check/test/doc/ide), or following MoonBit-specific layout, documentation, and testing conventions.</description>
        #|    <location>(mock:cwd)/.moonagent/skills/.system/moonbit-agent-guide/SKILL.md</location>
        #|  </skill>
        #|</available_skills>
      ),
    )
  })
}

///|
async test "load/lowercase" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      ".moonagent": {
        "skills": {
          "pdf-processing": {
            "skill.md": (
              #|---
              #|name: pdf-processing
              #|description: A skill to process PDF documents.
              #|version: 1.0.0
              #|---
              #|
              #|Use this skill to extract text from PDF files.
            ),
          },
        },
      },
    })
    let home = mock.cwd.path()
    // Add a `.git` marker so the loader stops walking up before reaching `home`.
    let cwd = @pathx.join(home, "cwd")
    mock.add_json_tree({ "cwd": { ".git": {} } })
    let loader = @skills.Loader::new(home~, cwd~)
    loader.load()
    let messages = [
      @ai.system_message(content="You are an AI assistant."),
      @ai.user_message(content="Please help me process this PDF document."),
    ]
    loader.load_and_apply(messages)
    guard messages is [System(content), ..] else {
      fail(
        "Messages have wrong structure, expecting [System(content), ..], got \{messages.to_json().stringify(indent=2)}",
      )
    }
    inspect(
      mock.text(content),
      content=(
        #|You are an AI assistant.
        #|
        #|====
        #|
        #|SKILLS
        #|
        #|You are equipped with skill capabilities that you can use to solve many
        #|tasks. A skill is a folder containing a SKILL.md file. This file includes:
        #|
        #|- name: The name of the skill
        #|- description: A brief description of what the skill does
        #|- location: The location of the skill on disk
        #|- instructions (as the main body): Instructions on how to use the skill.
        #|
        #|Optionally, a skill folder may also contain:
        #|
        #|- scripts: Python/Shell/... scripts for common operations
        #|- references: Reference materials such as documentation, cheat sheets,
        #|  etc.
        #|- templates: Code templates/snippets for common patterns
        #|
        #|Here is an example layout of a skill folder:
        #|
        #|```plaintext
        #|skills/
        #|  my-skill/
        #|    SKILL.md
        #|    scripts/
        #|      helper.py
        #|    references/
        #|      doc.md
        #|    templates/
        #|      snippet.mbt
        #|```
        #|
        #|To use skills efficiently, you should follow a progressive approach to
        #|discover, load and apply skills to tasks. Usually, this means:
        #|
        #|1. First, You should identify relevant skills for the task from the
        #|available skills list below.
        #|
        #|2. Next, You should load the identified skills into your working context,
        #|by reading their SKILL.md files. Note that you probably want to defer
        #|the loading of resources such as scripts, references, templates until they
        #|are actually needed.
        #|
        #|3. Finally, you should utilize the knowledge/rules/instructions provided
        #|by the loaded SKILL.md files to assist in completing the task. Optionally
        #|you may want to leverage the scripts/templates/references provided by
        #|the skill folders to accomplish the task.
        #|<available_skills>
        #|  <skill>
        #|    <name>moonbit-agent-guide</name>
        #|    <description>Guide for writing, refactoring, and testing MoonBit projects. Use when working in MoonBit modules or packages, organizing MoonBit files, using moon tooling (build/check/test/doc/ide), or following MoonBit-specific layout, documentation, and testing conventions.</description>
        #|    <location>(mock:cwd)/.moonagent/skills/.system/moonbit-agent-guide/SKILL.md</location>
        #|  </skill>
        #|  <skill>
        #|    <name>pdf-processing</name>
        #|    <description>A skill to process PDF documents.</description>
        #|    <location>(mock:cwd)/.moonagent/skills/pdf-processing/skill.md</location>
        #|  </skill>
        #|</available_skills>
      ),
    )
  })
}

///|
async test "load/invalid-skill" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      ".moonagent": {
        "skills": {
          "invalid-skill": {
            "SKILL.md": (
              #|---
              #|name: invalid-skill
              #|---
              #|
              #|This skill has an invalid format.
            ),
          },
        },
      },
    })
    let home = mock.cwd.path()
    let cwd = @pathx.join(home, "cwd")
    mock.add_json_tree({ "cwd": { ".git": {} } })
    let loader = @skills.Loader::new(home~, cwd~)
    loader.load()
    let messages = [
      @ai.system_message(content="You are an AI assistant."),
      @ai.user_message(content="Please help me process this PDF document."),
    ]
    loader.load_and_apply(messages)
    guard messages is [System(content), ..] else {
      fail(
        "Messages have wrong structure, expecting [System(content), ..], got \{messages.to_json().stringify(indent=2)}",
      )
    }
    inspect(
      mock.text(content),
      content=(
        #|You are an AI assistant.
        #|
        #|====
        #|
        #|SKILLS
        #|
        #|You are equipped with skill capabilities that you can use to solve many
        #|tasks. A skill is a folder containing a SKILL.md file. This file includes:
        #|
        #|- name: The name of the skill
        #|- description: A brief description of what the skill does
        #|- location: The location of the skill on disk
        #|- instructions (as the main body): Instructions on how to use the skill.
        #|
        #|Optionally, a skill folder may also contain:
        #|
        #|- scripts: Python/Shell/... scripts for common operations
        #|- references: Reference materials such as documentation, cheat sheets,
        #|  etc.
        #|- templates: Code templates/snippets for common patterns
        #|
        #|Here is an example layout of a skill folder:
        #|
        #|```plaintext
        #|skills/
        #|  my-skill/
        #|    SKILL.md
        #|    scripts/
        #|      helper.py
        #|    references/
        #|      doc.md
        #|    templates/
        #|      snippet.mbt
        #|```
        #|
        #|To use skills efficiently, you should follow a progressive approach to
        #|discover, load and apply skills to tasks. Usually, this means:
        #|
        #|1. First, You should identify relevant skills for the task from the
        #|available skills list below.
        #|
        #|2. Next, You should load the identified skills into your working context,
        #|by reading their SKILL.md files. Note that you probably want to defer
        #|the loading of resources such as scripts, references, templates until they
        #|are actually needed.
        #|
        #|3. Finally, you should utilize the knowledge/rules/instructions provided
        #|by the loaded SKILL.md files to assist in completing the task. Optionally
        #|you may want to leverage the scripts/templates/references provided by
        #|the skill folders to accomplish the task.
        #|<available_skills>
        #|  <skill>
        #|    <name>moonbit-agent-guide</name>
        #|    <description>Guide for writing, refactoring, and testing MoonBit projects. Use when working in MoonBit modules or packages, organizing MoonBit files, using moon tooling (build/check/test/doc/ide), or following MoonBit-specific layout, documentation, and testing conventions.</description>
        #|    <location>(mock:cwd)/.moonagent/skills/.system/moonbit-agent-guide/SKILL.md</location>
        #|  </skill>
        #|</available_skills>
      ),
    )
  })
}

///|
async test "reload" (t : @test.Test) {
  @mock.run(t, mock => {
    let skills = mock.add_directory(".moonagent").add_directory("skills")
    let pdf_processing = skills.add_directory("pdf-processing")
    let pdf_processing_skill = pdf_processing.add_file("SKILL.md")
    pdf_processing_skill.write_string(
      (
        #|---
        #|name: pdf-processing
        #|description: A skill to process PDF documents.
        #|version: 1.0.0
        #|---
        #|
        #|Use this skill to extract text from PDF files.
      ),
    )
    let home = mock.cwd.path()
    let cwd = @pathx.join(home, "cwd")
    // Mark `cwd` as a git repo so the loader stops there.
    mock.add_json_tree({ "cwd": { ".git": {} } })
    let loader = @skills.Loader::new(home~, cwd~)
    loader.load()
    @json.inspect(mock.json(loader.skills()), content={
      "moonbit-agent-guide": {
        "name": "moonbit-agent-guide",
        "description": "Guide for writing, refactoring, and testing MoonBit projects. Use when working in MoonBit modules or packages, organizing MoonBit files, using moon tooling (build/check/test/doc/ide), or following MoonBit-specific layout, documentation, and testing conventions.",
        "allowed_tools": [],
        "location": "(mock:cwd)/.moonagent/skills/.system/moonbit-agent-guide/SKILL.md",
      },
      "pdf-processing": {
        "name": "pdf-processing",
        "description": "A skill to process PDF documents.",
        "allowed_tools": [],
        "location": "(mock:cwd)/.moonagent/skills/pdf-processing/SKILL.md",
      },
    })
    // Update the skill
    pdf_processing_skill.write_string(
      (
        #|---
        #|name: pdf-processing
        #|description: An updated skill to process PDF documents.
        #|version: 1.1.0
        #|---
        #|
        #|Use this skill to extract text from PDF files with improved accuracy.
      ),
    )
    skills.add_json_tree({
      "text-summarization": {
        "SKILL.md": (
          #|---
          #|name: text-summarization
          #|description: A skill to summarize text documents.
          #|version: 1.0.0
          #|---
          #|
          #|Use this skill to generate summaries of text content.
        ),
      },
    })
    loader.load()
    @json.inspect(mock.json(loader.skills()), content={
      "moonbit-agent-guide": {
        "name": "moonbit-agent-guide",
        "description": "Guide for writing, refactoring, and testing MoonBit projects. Use when working in MoonBit modules or packages, organizing MoonBit files, using moon tooling (build/check/test/doc/ide), or following MoonBit-specific layout, documentation, and testing conventions.",
        "allowed_tools": [],
        "location": "(mock:cwd)/.moonagent/skills/.system/moonbit-agent-guide/SKILL.md",
      },
      "pdf-processing": {
        "name": "pdf-processing",
        "description": "An updated skill to process PDF documents.",
        "allowed_tools": [],
        "location": "(mock:cwd)/.moonagent/skills/pdf-processing/SKILL.md",
      },
      "text-summarization": {
        "name": "text-summarization",
        "description": "A skill to summarize text documents.",
        "allowed_tools": [],
        "location": "(mock:cwd)/.moonagent/skills/text-summarization/SKILL.md",
      },
    })
  })
}

///|
async test "load/parent-directories" (t : @test.Test) {
  @mock.run(t, mock => {
    // Directory layout:
    // (home)
    //   .moonagent/skills/global
    //   project/.moonagent/skills/project
    //   project/sub/.moonagent/skills/sub
    //   project/sub/deep (cwd)
    // and `project` is marked as a git repo root.
    mock.add_json_tree({
      ".moonagent": {
        "skills": {
          "global-skill": {
            "SKILL.md": (
              #|---
              #|name: global-skill
              #|description: Global skill.
              #|version: 1.0.0
              #|---
              #|
              #|Global instructions.
            ),
          },
        },
      },
      "project": {
        ".git": {},
        ".moonagent": {
          "skills": {
            "project-skill": {
              "SKILL.md": (
                #|---
                #|name: project-skill
                #|description: Project skill.
                #|version: 1.0.0
                #|---
                #|
                #|Project instructions.
              ),
            },
          },
        },
        "sub": {
          ".moonagent": {
            "skills": {
              "sub-skill": {
                "SKILL.md": (
                  #|---
                  #|name: sub-skill
                  #|description: Sub skill.
                  #|version: 1.0.0
                  #|---
                  #|
                  #|Sub instructions.
                ),
              },
            },
          },
          "deep": {},
        },
      },
    })
    let home = mock.cwd.path()
    let cwd = @pathx.join(home, "project/sub/deep")
    let loader = @skills.Loader::new(home~, cwd~)
    loader.load()
    // If inside a git repo, load skills from the repo root and all
    // ancestors down to cwd. That means project + sub, and still global.
    @json.inspect(mock.json(loader.skills()), content={
      "moonbit-agent-guide": {
        "name": "moonbit-agent-guide",
        "description": "Guide for writing, refactoring, and testing MoonBit projects. Use when working in MoonBit modules or packages, organizing MoonBit files, using moon tooling (build/check/test/doc/ide), or following MoonBit-specific layout, documentation, and testing conventions.",
        "allowed_tools": [],
        "location": "(mock:cwd)/.moonagent/skills/.system/moonbit-agent-guide/SKILL.md",
      },
      "global-skill": {
        "name": "global-skill",
        "description": "Global skill.",
        "allowed_tools": [],
        "location": "(mock:cwd)/.moonagent/skills/global-skill/SKILL.md",
      },
      "project-skill": {
        "name": "project-skill",
        "description": "Project skill.",
        "allowed_tools": [],
        "location": "(mock:cwd)/project/.moonagent/skills/project-skill/SKILL.md",
      },
      "sub-skill": {
        "name": "sub-skill",
        "description": "Sub skill.",
        "allowed_tools": [],
        "location": "(mock:cwd)/project/sub/.moonagent/skills/sub-skill/SKILL.md",
      },
    })
  })
}

///|
async test "load/no-git-loads-cwd-and-home" (t : @test.Test) {
  @mock.run(t, mock => {
    // Directory layout:
    // (home)
    //   .moonagent/skills/global
    //   cwd/.moonagent/skills/local
    // and there is NO `.git` anywhere.
    mock.add_json_tree({
      ".moonagent": {
        "skills": {
          "global-skill": {
            "SKILL.md": (
              #|---
              #|name: global-skill
              #|description: Global skill.
              #|version: 1.0.0
              #|---
              #|
              #|Global instructions.
            ),
          },
        },
      },
      "cwd": {
        ".moonagent": {
          "skills": {
            "local-skill": {
              "SKILL.md": (
                #|---
                #|name: local-skill
                #|description: Local skill.
                #|version: 1.0.0
                #|---
                #|
                #|Local instructions.
              ),
            },
          },
        },
      },
    })
    let home = mock.cwd.path()
    let cwd = @pathx.join(home, "cwd")
    let loader = @skills.Loader::new(home~, cwd~)
    loader.load()
    @json.inspect(mock.json(loader.skills()), content={
      "moonbit-agent-guide": {
        "name": "moonbit-agent-guide",
        "description": "Guide for writing, refactoring, and testing MoonBit projects. Use when working in MoonBit modules or packages, organizing MoonBit files, using moon tooling (build/check/test/doc/ide), or following MoonBit-specific layout, documentation, and testing conventions.",
        "allowed_tools": [],
        "location": "(mock:cwd)/.moonagent/skills/.system/moonbit-agent-guide/SKILL.md",
      },
      "global-skill": {
        "name": "global-skill",
        "description": "Global skill.",
        "allowed_tools": [],
        "location": "(mock:cwd)/.moonagent/skills/global-skill/SKILL.md",
      },
      "local-skill": {
        "name": "local-skill",
        "description": "Local skill.",
        "allowed_tools": [],
        "location": "(mock:cwd)/cwd/.moonagent/skills/local-skill/SKILL.md",
      },
    })
  })
}
