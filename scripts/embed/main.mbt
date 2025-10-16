///|
priv suberror MissingArgument String

///|
impl Show for MissingArgument with output(
  self : MissingArgument,
  logger : &Logger,
) -> Unit {
  let MissingArgument(name) = self
  logger.write_string("Missing argument: \{name}")
}

///|
priv suberror UnrecognizedArgument String

///|
impl Show for UnrecognizedArgument with output(
  self : UnrecognizedArgument,
  logger : &Logger,
) -> Unit {
  let UnrecognizedArgument(arg) = self
  logger.write_string("Unrecognized argument: \{arg}")
}

///|
struct Arguments {
  mut name : String
  mut public : Bool
  mut source : String?
  mut destination : String?
  mut is_const : Bool
}

///|
async fn main {
  try {
    let args = @env.args()
    guard args is [_, .. args]
    let arguments = {
      name: "resource",
      public: false,
      source: None,
      destination: None,
      is_const: false,
    }
    loop args {
      ["--name", name, .. rest] => {
        arguments.name = name
        if name is ['A'..='Z', ..] {
          arguments.is_const = true
        }
        continue rest
      }
      ["--name"] => raise MissingArgument("name")
      ["--pub", .. rest] => {
        arguments.public = true
        continue rest
      }
      ["--output" | "-o", path, .. rest] if arguments.destination is None => {
        arguments.destination = Some(path)
        continue rest
      }
      ["--output" | "-o"] => raise MissingArgument("output")
      [path, .. rest] if arguments.source is None => {
        arguments.source = Some(path)
        continue rest
      }
      [argument, ..] => raise UnrecognizedArgument(argument)
      [] => break
    }
    guard arguments.source is Some(source) else {
      raise MissingArgument("path")
    }
    let destination = match arguments.destination {
      Some(path) => path
      None => "\{source}.mbt"
    }
    println("EMBED \{source} -> \{destination}")
    let text = @fs.read_file(source).text()
    let lines = ["///|"]
    if arguments.public {
      if arguments.is_const {
        lines.push("pub const \{arguments.name} : String =")
      } else {
        lines.push("pub let \{arguments.name} : String =")
      }
    } else if arguments.is_const {
      lines.push("const \{arguments.name} : String =")
    } else {
      lines.push("let \{arguments.name} : String =")
    }
    for line in text.split("\n") {
      lines.push("  #|\{line}")
    }
    lines.push("")
    @fs.write_file(
      destination,
      @encoding/utf8.encode(lines.join("\n")),
      create=0o644,
      truncate=true,
    )
  } catch {
    error => println("Error: \{error}")
  }
}
