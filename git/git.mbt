///|
pub async fn clone(url : String, to~ : String) -> Unit raise {
  let status = @process.run("git", [
    "clone",
    @utf8.encode(url),
    @utf8.encode(to),
  ])
  if status != 0 {
    fail("git clone failed with status code \{status}")
  }
}

///|
pub async fn init_(path : String, output? : &Logger) -> Unit raise {
  let status = @spawn.to("git", ["init", path], output?)
  if status != 0 {
    fail("git init failed with status code \{status}")
  }
}

///|
pub async fn commit(
  message : String,
  files : Array[String],
  output? : &Logger,
  cwd? : String,
) -> Unit {
  let buffer = StringBuilder::new()
  let status = @spawn.to("git", ["add", ..files], output=buffer, cwd?)
  guard status is 0 else {
    fail("git add failed with \{status}: \{buffer.to_string()}")
  }
  let status = @spawn.to("git", ["commit", "-m", message], output=buffer, cwd?)
  guard status is 0 else {
    fail("git commit failed with \{status}: \{buffer.to_string()}")
  }
  if output is Some(output) {
    output.write_string(buffer.to_string())
  }
}

///|
pub async fn create_branch(branch_name~ : String, cwd? : String) -> String {
  let cwd = cwd.map(@utf8.encode(_))
  guard @process.run("git", ["branch", @utf8.encode(branch_name)], cwd?) is 0 else {
    fail("git branch creation failed")
  }
  return "Branch '\{branch_name}' created successfully"
}

///|
let uv : Result[@uv.Loop, @uv.Errno] = try? @uv.Loop::new()

///|
pub async fn generate_git_diff(
  original~ : String,
  modified~ : String,
) -> String raise {
  let template = @path.join(
    @uv.os_tmpdir(),
    @utf8.encode("maria-git-diff-XXXXXX"),
  )
  println("template: \{@utf8.decode(template)}")
  let tmpdir = uv.unwrap_or_error().fs_mkdtemp_sync(template)
  println("tmpdir: \{@utf8.decode(tmpdir)}")
  if !@fs.exists(tmpdir) {
    @fs.mkdir(tmpdir, permission=0o755) catch {
      err => fail("failed to create temporary directory: \{err}")
    }
    println("created temporary directory")
  } else {
    println("temporary directory already exists")
  }
  @async.with_task_group(group => {
    let original_path = @path.join(tmpdir, @utf8.encode("original.txt"))
    println("original_path: \{@utf8.decode(original_path)}")
    @fs.write_file(original_path, @utf8.encode(original), create=0o644)
    println("written original")
    let modified_path = @path.join(tmpdir, @utf8.encode("modified.txt"))
    println("modified_path: \{@utf8.decode(modified_path)}")
    @fs.write_file(modified_path, @utf8.encode(modified), create=0o644)
    println("written modified")
    let buffer = @buffer.new()
    group.add_defer(() => @fs.remove(original_path))
    group.add_defer(() => @fs.remove(modified_path))
    let (reader, writer) = @process.read_from_process()
    group.spawn_bg(() => {
      let buf : FixedArray[Byte] = FixedArray::make(4096, 0)
      loop reader.read(buf) {
        0 => break
        n => {
          buffer.write_bytesview(buf.unsafe_reinterpret_as_bytes()[0:n])
          continue reader.read(buf)
        }
      }
    })
    @process.run(
      "git",
      [
        "diff", "--no-index", "--no-index", "--no-prefix", "--unified=3", original_path,
        modified_path,
      ],
      stdout=writer,
      stderr=writer,
    )
    |> ignore()
    @utf8.decode(buffer.contents())
  })
}
