///|
fn main {
  guard @env.args() is [_, input, "-o", output] else {
    abort(
      "Invalid arguments. Usage: derive_json_schema input.mbt -o output.mbt",
    )
  }
  guard @fs.path_exists(input) else {
    abort("Invalid argument: \{input} file not exist.")
  }
  guard input.has_suffix(".mbt") else {
    abort("Invalid argument: \{input} is not a .mbt file")
  }
  try {
    let source = @fs.read_file_to_string(input)
    let (ast, report) = @parser.parse_string(source)
    guard report is [] else {
      abort("Parse error in \{input}: \{report.to_json().stringify(indent=2)}")
    }
    let ast = derive_json_schema(ast)
    let result = @formatter.impls_to_string(ast)
    @fs.write_string_to_file(output, result)
  } catch {
    e => abort(e.to_string())
  }
}

///|
fn[T] abort(msg : String) -> T {
  println(msg)
  panic()
}
